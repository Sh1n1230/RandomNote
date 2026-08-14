import SwiftUI
import UIKit

/// 生メモをLLMに投げて「タイトル＋本文」に整えてもらうためのプロンプトを置いておく画面
struct ImportPromptView: View {
    @State private var didCopy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                Text("使いかた").dsMicroLabel()
                Text("書き殴ったメモをまとめてLLMに渡し、このアプリのタイトル／本文の形に整えてもらうためのプロンプトです。コピーして、末尾に生メモを貼り付けて使ってください。")
                    .dsCallout()
                Text(ImportPrompt.text)
                    .font(.footnote.monospaced())
                    .foregroundStyle(DS.Color.ink)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .dsCard(padding: DS.Space.lg, radius: DS.Radius.control)
            }
            .padding(DS.Space.screenMargin)
        }
        .background(DS.Color.canvas)
        .safeAreaInset(edge: .bottom) {
            Button(action: copy) {
                Label(didCopy ? "コピーしました" : "プロンプトをコピー",
                      systemImage: didCopy ? "checkmark" : "doc.on.doc")
            }
            .buttonStyle(.dsPrimary)
            .padding(DS.Space.screenMargin)
            .background(.bar)
        }
        .navigationTitle("AI用プロンプト")
        .navigationBarTitleDisplayMode(.inline)
        .tint(DS.Color.accent)
    }

    private func copy() {
        UIPasteboard.general.string = ImportPrompt.text
        withAnimation(DS.Motion.quick) { didCopy = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(DS.Motion.quick) { didCopy = false }
        }
    }
}

enum ImportPrompt {
    static let text = """
    あなたは、私が読書や人の話から書き殴ったメモを、あとから読み返して価値のある「一枚のカード」に整える編集者です。

    以下の【生メモ】を読み、独立した知見ごとに1件のメモへ分割・推敲してください。

    # ルール
    - 1件のメモには主張を1つだけ入れる。複数の話題が混ざっていれば分割する。
    - タイトルは、その知見を一文で言い切った20文字前後の断定形にする。「〜について」のような主題ラベルにはしない。
    - 本文は2〜4文。前後の文脈がなくても意味が通るよう、指示語や内輪の略語は具体的に開く。
    - 私が書いた内容の意味を変えない。書かれていない事実・数字・出典を足さない。
    - 冗長な言い回しは削るが、私の言葉づかいや比喩は残す。
    - 同じ趣旨のメモが複数あれば1件にまとめる。
    - 断片的すぎて主張が復元できないものは出力しない。
    - 出力は日本語。

    # 出力フォーマット
    下記の形式だけを、メモの件数ぶん繰り返して出力する。前置き・総括・通し番号は付けない。

    ---
    タイトル: <ここにタイトル>
    本文: <ここに本文>
    ---

    # 生メモ
    （ここに生メモを貼り付ける）
    """
}
