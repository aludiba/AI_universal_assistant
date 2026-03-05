allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// 为缺少 namespace 的第三方插件自动注入（AGP 8+ 必需）
subprojects {
    plugins.withId("com.android.library") {
        val androidExt = extensions.findByName("android") ?: return@withId
        val getNamespace = androidExt.javaClass.methods.firstOrNull {
            it.name == "getNamespace" && it.parameterCount == 0
        } ?: return@withId
        val setNamespace = androidExt.javaClass.methods.firstOrNull {
            it.name == "setNamespace" && it.parameterCount == 1
        } ?: return@withId

        val currentNamespace = getNamespace.invoke(androidExt) as? String
        if (currentNamespace.isNullOrBlank()) {
            val manifest = file("${project.projectDir}/src/main/AndroidManifest.xml")
            val manifestPackage = if (manifest.exists()) {
                Regex("package=\"([^\"]+)\"")
                    .find(manifest.readText())
                    ?.groupValues
                    ?.get(1)
            } else {
                null
            }
            val fallbackNamespace = project.group.toString()
                .takeIf { it.isNotBlank() && it != "unspecified" }
                ?: "com.${project.name.replace("-", ".")}"

            setNamespace.invoke(androidExt, manifestPackage ?: fallbackNamespace)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
