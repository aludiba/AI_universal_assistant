//
//  AIUAConfigID.h
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/6/25.
//

#ifndef AIUAConfigID_h
#define AIUAConfigID_h


// DeepSeek
#define APIKEY               @"sk-ecdd2f67aa60478bab7cb3fdd0e83343"  //DeepSeek申请的apikey

// 穿山甲广告SDK配置
// 使用说明：
// 1. 在穿山甲广告平台（https://www.csjplatform.com/）注册账号
// 2. 创建应用并获取AppID
// 3. 创建开屏广告位并获取代码位ID
// 4. 将对应的ID填入下方宏定义中

// ========== 测试配置（当前使用，可以立即看到广告） ==========
#define AIUA_APPID               @"5755016"      // 测试AppID
#define AIUA_SPLASH_AD_SLOT_ID   @"893331808"   // 测试开屏广告代码位
//#define AIUA_APPID               @"5603361"      // 测试AppID
//#define AIUA_SPLASH_AD_SLOT_ID   @"890787307"   // 测试开屏广告代码位
#define AIUA_REWARD_AD_SLOT_ID   @"972751105"   // 测试激励视频代码位（请在平台替换为你的正式ID）

// ========== 你的正式配置（等测试成功后再使用） ==========
// 新创建的代码位需要1-3天审核激活，激活后再替换下面的配置
// #define AIUA_APPID               @"5755016"      // 你的正式AppID
// #define AIUA_SPLASH_AD_SLOT_ID   @"893331808"   // 你的正式代码位
// #define AIUA_REWARD_AD_SLOT_ID   @"945113162"   // 你的正式激励视频代码位

#define AIUA_APPName             @"AI Universal Assistant"  // 应用名称
#define AIUA_BU_APP_KEY          @""  // 穿山甲AppKey（已废弃，使用AIUA_APPID）

// 广告开关（同时控制是否编译穿山甲SDK）
// 设置为0时：关闭广告功能，不编译穿山甲SDK（模拟器开发时建议设为0以避免链接错误）
// 设置为1时：开启广告功能，编译穿山甲SDK（真机测试或发布时使用）
#define AIUA_AD_ENABLED          0    // 1: 开启广告并编译SDK  0: 关闭广告且不编译SDK

// 会员订阅检测开关（如果不想进行会员订阅检测，设置为0，所有用户将被视为VIP）
#define AIUA_VIP_CHECK_ENABLED   0    // 1: 开启会员检测  0: 关闭会员检测（所有用户视为VIP）

// 过期字数包提醒测试开关（用于测试过期提醒功能）
#define AIUA_EXPIRING_WORDS_TEST_ENABLED   0    // 1: 开启测试数据  0: 关闭测试数据（使用真实数据）

// 调试错误日志弹窗开关（开发/测试时设为1，发布时设为0）
#define AIUA_SHOW_DEBUG_ERROR_ALERTS 1

// 清除购买数据功能开关（开发/测试时设为1，发布时必须设为0）
// 警告：此功能会清除所有订阅和字数包数据，仅用于测试！
#define AIUA_ENABLE_CLEAR_PURCHASE_DATA 0

// ========== IAP产品ID配置 ==========
// 说明：
// 1. 如果定义了自定义产品ID，则使用自定义的（确保与App Store Connect中的完全一致）
// 2. 如果未定义，则自动基于Bundle ID生成（格式: {BundleID}.lifetimeBenefits等）
// 3. 产品ID必须与App Store Connect后台创建的产品ID完全一致（区分大小写）
// 4. 如果产品正在审核，需要等待审核完成后才能在沙盒环境测试

// 订阅产品ID配置（可选，如果定义了则使用，否则自动生成）
 #define AIUA_IAP_PRODUCT_LIFETIME    @"com.hujiaofen.writingCat.lifetimeBenefits"
 #define AIUA_IAP_PRODUCT_YEARLY      @"com.hujiaofen.writingCat.yearly"
 #define AIUA_IAP_PRODUCT_MONTHLY     @"com.hujiaofen.writingCat.monthly"
 #define AIUA_IAP_PRODUCT_WEEKLY      @"com.hujiaofen.writingCat.weekly"

 // 字数包产品ID配置（可选，如果定义了则使用，否则自动生成）
 #define AIUA_IAP_WORDPACK_500K       @"com.yourcompany.aiassistant.wordpack.500k"
 #define AIUA_IAP_WORDPACK_2M         @"com.yourcompany.aiassistant.wordpack.2m"
 #define AIUA_IAP_WORDPACK_6M         @"com.yourcompany.aiassistant.wordpack.6m"

#endif /* AIUAConfigID_h */
