import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WriteDiary AI プライバシーポリシー',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '最終更新日: 2026年1月13日',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'はじめに',
              'WriteDiary AI（以下「本アプリ」といいます）は、ユーザーのプライバシーを尊重し、個人情報の保護に努めています。本プライバシーポリシーは、本アプリがどのような情報を収集し、どのように使用するかを説明するものです。',
            ),
            _buildSection(
              context,
              '1. 収集する情報',
              '''本アプリは、以下の情報を収集することがあります：

【アカウント情報】
• メールアドレス
• 表示名（任意）
• パスワード（暗号化して保存）

【利用データ】
• 作成した日記の内容
• AI添削の履歴
• 復習カードのデータ
• 手書きスキャンの使用回数

【デバイス情報】
• デバイスの種類
• オペレーティングシステム
• アプリのバージョン''',
            ),
            _buildSection(
              context,
              '2. 情報の使用目的',
              '''収集した情報は、以下の目的で使用します：

• 本アプリのサービス提供
• AI添削機能の実行
• ユーザーアカウントの管理
• サービスの改善と新機能の開発
• ユーザーサポートの提供
• 利用規約の遵守確認''',
            ),
            _buildSection(
              context,
              '3. 情報の共有',
              '''本アプリは、以下の場合を除き、ユーザーの個人情報を第三者と共有することはありません：

• ユーザーの同意がある場合
• 法令に基づく開示請求があった場合
• サービス提供に必要な業務委託先との共有（AWS等のクラウドサービスプロバイダー）

【AI処理について】
日記の添削機能には、Amazon Web Services（AWS）のBedrock AIサービスを使用しています。ユーザーの日記内容はAI処理のためにAWSに送信されますが、AWSのプライバシーポリシーに従って処理されます。''',
            ),
            _buildSection(
              context,
              '4. データの保存',
              '''ユーザーのデータは、Amazon Web Services（AWS）のサーバーに安全に保存されます。

【保存場所】
• 主要データ: AWS 東京リージョン（ap-northeast-1）
• AI処理: AWS 米国東部リージョン（us-east-1）

【保存期間】
• アカウント削除まで保存
• アカウント削除後は速やかに削除''',
            ),
            _buildSection(
              context,
              '5. データのセキュリティ',
              '''本アプリは、ユーザーのデータを保護するために以下の対策を講じています：

• 通信の暗号化（HTTPS/TLS）
• パスワードの暗号化保存
• アクセス制御とユーザー認証
• 定期的なセキュリティ監査''',
            ),
            _buildSection(
              context,
              '6. ユーザーの権利',
              '''ユーザーは以下の権利を有します：

• 自身のデータへのアクセス権
• データの訂正・更新権
• アカウントとデータの削除権
• データのエクスポート権（今後対応予定）

これらの権利を行使するには、アプリ内の設定画面から操作するか、サポートにお問い合わせください。''',
            ),
            _buildSection(
              context,
              '7. Cookie等の使用',
              '本アプリはモバイルアプリであり、ブラウザのCookieは使用しません。ただし、認証状態を維持するためにセキュアなトークンを端末に保存することがあります。',
            ),
            _buildSection(
              context,
              '8. 子どものプライバシー',
              '本アプリは、13歳未満の子どもを対象としたサービスではありません。13歳未満の方が本アプリを使用していることが判明した場合、そのアカウントとデータを削除することがあります。',
            ),
            _buildSection(
              context,
              '9. プライバシーポリシーの変更',
              '本プライバシーポリシーは、必要に応じて変更されることがあります。重要な変更がある場合は、アプリ内通知またはメールでお知らせします。',
            ),
            _buildSection(
              context,
              '10. お問い合わせ',
              '''本プライバシーポリシーに関するご質問やご意見がございましたら、以下までお問い合わせください：

メール: support@writediary-ai.example.com''',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}
