import SwiftUI

struct NoteCardView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(note.createdAt, format: .dateTime.year().month().day())
                .dsMicroLabel()
            Text(note.displayTitle)
                .dsTitle()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, DS.Space.sm)
            Rectangle()
                .fill(DS.Color.border)
                .frame(height: 1)
                .padding(.vertical, DS.Space.lg)
            Text(note.content)
                .dsBody()
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            if !note.tags.isEmpty {
                FlowLayout(spacing: DS.Space.xs) {
                    ForEach(note.tags, id: \.self) { DSChip(title: $0, compact: true) }
                }
                .padding(.top, DS.Space.lg)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .dsCard()
    }
}
