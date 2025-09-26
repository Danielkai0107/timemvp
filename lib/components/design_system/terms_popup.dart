import 'package:flutter/material.dart';
import 'custom_button.dart';

/// 服務條款滿版彈窗組件
class TermsPopup extends StatelessWidget {
  const TermsPopup({
    super.key,
    required this.title,
    required this.content,
    this.onClose,
  });

  /// 標題
  final String title;
  
  /// 內容
  final String content;
  
  /// 關閉回調
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          // 點擊空白區域時取消焦點
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            bottom: 40.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 關閉按鈕區域 - 距離上方60px
              const SizedBox(height: 40),
              CustomButton(
                onPressed: onClose ?? () {
                  // 關閉前確保取消焦點
                  FocusScope.of(context).unfocus();
                  Navigator.of(context).pop();
                },
                text: '關閉',
                width: 80,
                style: CustomButtonStyle.info,
                borderRadius: 30.0, // 完全圓角
              ),
              
              const SizedBox(height: 24),
              
              // 標題
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 內容區域
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.grey,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

/// 服務條款彈窗建構器
class TermsPopupBuilder {
  /// 顯示服務條款彈窗
  static Future<void> showTermsOfService(BuildContext context) async {
    // 先取消當前頁面的焦點
    FocusScope.of(context).unfocus();
    
    // 稍微延遲確保焦點狀態清除
    await Future.delayed(const Duration(milliseconds: 100));
    
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const TermsPopup(
          title: '服務條款',
          content: _termsOfServiceContent,
        ),
      ),
    );
    
    // 彈窗關閉後再次確保沒有焦點
    if (context.mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  /// 顯示隱私權政策彈窗
  static Future<void> showPrivacyPolicy(BuildContext context) async {
    // 先取消當前頁面的焦點
    FocusScope.of(context).unfocus();
    
    // 稍微延遲確保焦點狀態清除
    await Future.delayed(const Duration(milliseconds: 100));
    
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const TermsPopup(
          title: '隱私權政策',
          content: _privacyPolicyContent,
        ),
      ),
    );
    
    // 彈窗關閉後再次確保沒有焦點
    if (context.mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  /// 顯示自定義內容彈窗
  static void showCustomContent(
    BuildContext context, {
    required String title,
    required String content,
    VoidCallback? onClose,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => TermsPopup(
          title: title,
          content: content,
          onClose: onClose,
        ),
      ),
    );
  }
}

/// 服務條款內容
const String _termsOfServiceContent = '''
【隱私政策暨個資聲明】
本隱私政策適用於貴服務商所有網站平臺以及我們的應用程式。請仔細閱讀，以下為相關個人資料保護政策的更多內容。

一、隱私權保護政策的適用範圍
隱私權保護政策內容，包括本服務或（Worky平台）友善用服務，如何處理在您使用（網路服務時收集到的個人識別資料，隱私權保護政策不適用於本服務以外的相關連結網站，也不適用於非本服務所委託或參與管理的人員。

二、個人資料的蒐集使用方式
為了在本網站、行動應用程式或其他互動性平臺服務上為您提供更好個人化服務，其範圍如下：

當您至本網站瀏覽、註冊、留下基本個人資料、購買產品等互動作功能時，會保留您所提供的姓名、身分證字號（統一編號）、出生年月日、性別、職稱、住址、電子公司地址、電話、傳真、電子郵件、使用時間等略。

當您使用本網站與你使用Worky平台服務的體驗，需要付款界券號付您提供的姓名，身份證號碼或統一編號，通訊地址或電子郵件地址，以及商品與服務相關必要資訊，加值服務，或是邀請您進行新體驗資訊收集，以及其他經您書面同意之資訊。

為提供個人化服務與其他加值服務，可能會請您提供資訊，包括但不限定於您使用服務時所瀏覽或查詢的資料、您的IP位址、使用時間、使用的瀏覽器、瀏覽及點選資料紀錄等資料。

三、資料的使用
（一）本服務站絕不會提供、交換、出租或出售任何您的個人資料，以下情況除外：
1.事先獲得您明確的同意。
2.由於您將用戶密碼告知他人或與他人共享註冊帳戶，由此導致的任何個人資料洩露。
3.根據法律相關規定或政府相關政策需要不得不提供。
4.為了保護本服務站系統及使用者的權利或財產安全。

（二）如因業務需要有必要委託其他單位提供服務時，本服務站亦會嚴格要求其遵守保密義務，並且採取必要檢查程序以確定其將確實遵守。

四、隱私政策的修訂與變更
本網站的隱私政策可能提供其他國際應用程式的需求，你可以查看最新網站或提供最佳服務不增加的服務新資料處理，你的消費者權益選擇的用者的問應該會獲得。''';

/// 隱私權政策內容
const String _privacyPolicyContent = '''
【隱私權政策】
感謝您使用我們的服務。您的隱私對我們而言非常重要，本隱私權政策說明我們如何收集、使用、儲存和保護您的個人資料。

一、資料收集
我們可能收集以下類型的資料：
1. 個人識別資料：姓名、電子郵件地址、電話號碼等。
2. 使用資料：您如何使用我們的服務、偏好設定等。
3. 技術資料：IP地址、瀏覽器類型、作業系統等。

二、資料使用
我們使用收集到的資料用於：
1. 提供和改善我們的服務
2. 與您溝通
3. 遵守法律要求
4. 保護我們的權利和安全

三、資料保護
我們採取適當的技術和組織措施來保護您的個人資料，防止未經授權的訪問、使用或披露。

四、資料分享
除非得到您的明確同意或法律要求，我們不會與第三方分享您的個人資料。

五、您的權利
您有權：
1. 訪問您的個人資料
2. 更正不準確的資料
3. 刪除您的資料
4. 反對處理您的資料

六、聯繫我們
如果您對本隱私權政策有任何問題，請透過以下方式聯繫我們：
電子郵件：privacy@example.com

本政策的最後更新日期：2024年12月。''';
