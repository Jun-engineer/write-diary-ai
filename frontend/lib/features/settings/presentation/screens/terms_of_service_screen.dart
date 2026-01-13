import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('利用規約'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WriteDiary AI 利用規約',
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
              '第1条（適用）',
              '本規約は、WriteDiary AI（以下「本アプリ」といいます）が提供するすべてのサービスの利用条件を定めるものです。ユーザーは、本規約に同意したうえで、本アプリを利用するものとします。',
            ),
            _buildSection(
              context,
              '第2条（利用登録）',
              '''1. 本アプリの利用を希望する方は、本規約に同意の上、所定の方法によって利用登録を申請し、運営者がこれを承認することによって、利用登録が完了するものとします。
2. 運営者は、利用登録の申請者に以下の事由があると判断した場合、利用登録の申請を承認しないことがあり、その理由については一切の開示義務を負わないものとします。
   - 虚偽の事項を届け出た場合
   - 本規約に違反したことがある者からの申請である場合
   - その他、運営者が利用登録を相当でないと判断した場合''',
            ),
            _buildSection(
              context,
              '第3条（禁止事項）',
              '''ユーザーは、本アプリの利用にあたり、以下の行為をしてはなりません。
1. 法令または公序良俗に違反する行為
2. 犯罪行為に関連する行為
3. 運営者のサーバーまたはネットワークの機能を破壊したり、妨害したりする行為
4. 本アプリの運営を妨害するおそれのある行為
5. 他のユーザーに関する個人情報等を収集または蓄積する行為
6. 他のユーザーに成りすます行為
7. 運営者のサービスに関連して、反社会的勢力に対して直接または間接に利益を供与する行為
8. その他、運営者が不適切と判断する行為''',
            ),
            _buildSection(
              context,
              '第4条（本アプリの提供の停止等）',
              '''1. 運営者は、以下のいずれかの事由があると判断した場合、ユーザーに事前に通知することなく本アプリの全部または一部の提供を停止または中断することができるものとします。
   - 本アプリにかかるコンピュータシステムの保守点検または更新を行う場合
   - 地震、落雷、火災、停電または天災などの不可抗力により、本アプリの提供が困難となった場合
   - コンピュータまたは通信回線等が事故により停止した場合
   - その他、運営者が本アプリの提供が困難と判断した場合
2. 運営者は、本アプリの提供の停止または中断により、ユーザーまたは第三者が被ったいかなる不利益または損害について、理由を問わず一切の責任を負わないものとします。''',
            ),
            _buildSection(
              context,
              '第5条（著作権）',
              '1. ユーザーは、自ら著作権等の必要な知的財産権を有するか、または必要な権利者の許諾を得た文章、画像等のみ、本アプリを利用して投稿することができるものとします。\n2. ユーザーが本アプリを利用して投稿した文章等の著作権については、当該ユーザーに留保されるものとします。',
            ),
            _buildSection(
              context,
              '第6条（AI添削サービス）',
              '''1. 本アプリのAI添削機能は、Amazon Web Services（AWS）のAIサービスを利用しています。
2. AI添削の結果は参考情報であり、その正確性、完全性を保証するものではありません。
3. AI添削機能の利用により生じた損害について、運営者は一切の責任を負いません。''',
            ),
            _buildSection(
              context,
              '第7条（免責事項）',
              '''1. 運営者は、本アプリに事実上または法律上の瑕疵（安全性、信頼性、正確性、完全性、有効性、特定の目的への適合性、セキュリティなどに関する欠陥、エラーやバグ、権利侵害などを含みます）がないことを保証するものではありません。
2. 運営者は、本アプリによってユーザーに生じたあらゆる損害について、一切の責任を負いません。''',
            ),
            _buildSection(
              context,
              '第8条（サービス内容の変更等）',
              '運営者は、ユーザーに通知することなく、本アプリの内容を変更しまたは本アプリの提供を中止することができるものとし、これによってユーザーに生じた損害について一切の責任を負いません。',
            ),
            _buildSection(
              context,
              '第9条（利用規約の変更）',
              '運営者は、必要と判断した場合には、ユーザーに通知することなくいつでも本規約を変更することができるものとします。',
            ),
            _buildSection(
              context,
              '第10条（準拠法・裁判管轄）',
              '本規約の解釈にあたっては、日本法を準拠法とします。本アプリに関して紛争が生じた場合には、東京地方裁判所を第一審の専属的合意管轄とします。',
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
