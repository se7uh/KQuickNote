// Import necessary modules for KDE Plasma widget development
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import QtQuick.Effects
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.core as PlasmaCore
import QtQuick.Window

// Main widget component
PlasmoidItem {
    id: root
    
    // Store notes data and track active text area
    property var notesModel: ListModel {}
    property Item activeTextArea: null

    // Handle clicks outside notes to unfocus the active text area
    MouseArea {
        anchors.fill: parent
        z: -1  // Behind everything
        onClicked: {
            if (activeTextArea) {
                activeTextArea.focus = false
                activeTextArea = null
            }
        }
    }

    // Widget size in panel mode
    switchWidth: Kirigami.Units.gridUnit * 5
    switchHeight: Kirigami.Units.gridUnit * 5

    // System tray integration
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    toolTipMainText: "KQuickNote"
    toolTipSubText: notesModel.count > 0 ? notesModel.get(0).content.substring(0, 50) + "..." : "No notes yet"
    toolTipTextFormat: Text.PlainText

    // Widget icon in system tray
    Plasmoid.icon: "accessories-text-editor"

    // Delete confirmation dialog component
    PC3.Dialog {
        id: deleteConfirmDialog
        parent: root
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        modal: true
        
        property int noteIndex: -1
        property bool deleteAll: false

        title: deleteAll ? "Clear All Notes" : "Delete Note"

        // Dialog content
        contentItem: ColumnLayout {
            spacing: Kirigami.Units.largeSpacing
            implicitWidth: Kirigami.Units.gridUnit * 20

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing
                
                Kirigami.Icon {
                    source: "dialog-warning"
                    width: Kirigami.Units.iconSizes.large
                    height: width
                }

                PC3.Label {
                    Layout.fillWidth: true
                    text: deleteConfirmDialog.deleteAll ? 
                        "Are you sure you want to delete all notes?" :
                        "Are you sure you want to delete this note?"
                    wrapMode: Text.Wrap
                }
            }
        }

        // Dialog buttons
        footer: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Item { Layout.fillWidth: true }

            PC3.Button {
                text: "Cancel"
                icon.name: "dialog-cancel"
                onClicked: deleteConfirmDialog.close()
            }

            PC3.Button {
                text: "Delete"
                icon.name: "edit-delete"
                onClicked: {
                    if (deleteConfirmDialog.deleteAll) {
                        notesModel.clear()
                    } else if (deleteConfirmDialog.noteIndex >= 0) {
                        notesModel.remove(deleteConfirmDialog.noteIndex)
                    }
                    saveNotes()
                    deleteConfirmDialog.close()
                }
            }
        }
    }

    // Compact representation (system tray icon)
    compactRepresentation: Item {
        id: compactRoot
        
        // Set size constraints
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small
        Layout.preferredWidth: Kirigami.Units.iconSizes.small
        Layout.preferredHeight: Kirigami.Units.iconSizes.small
        Layout.maximumWidth: Kirigami.Units.iconSizes.enormous
        Layout.maximumHeight: Kirigami.Units.iconSizes.enormous

        PC3.ToolButton {
            id: button
            anchors.fill: parent
            icon.name: "accessories-text-editor"
            display: PC3.ToolButton.IconOnly
            text: "KQuickNote"
            
            onClicked: root.expanded = !root.expanded
        }
    }
    
    // Full representation (main widget window)
    fullRepresentation: PlasmaExtras.Representation {
        id: dialogItem
        
        // Set size constraints for the main window
        Layout.minimumWidth: Kirigami.Units.gridUnit * 24
        Layout.minimumHeight: Kirigami.Units.gridUnit * 24
        Layout.maximumWidth: Kirigami.Units.gridUnit * 40
        Layout.maximumHeight: Kirigami.Units.gridUnit * 40
        
        collapseMarginsHint: true
        focus: true

        // Main content layout
        contentItem: ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            // Header with title and action buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                PC3.Label {
                    text: "My Notes"
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.5
                    font.weight: Font.Medium
                }

                Item { Layout.fillWidth: true }

                // New note button
                PC3.Button {
                    icon.name: "list-add"
                    text: "New Note"
                    onClicked: {
                        notesModel.append({ title: "New Note", content: "", isEditing: true })
                        saveNotes()
                    }
                }

                // Clear all button
                PC3.Button {
                    icon.name: "edit-delete"
                    text: "Clear All"
                    visible: notesModel.count > 0
                    onClicked: {
                        deleteConfirmDialog.deleteAll = true
                        deleteConfirmDialog.noteIndex = -1
                        deleteConfirmDialog.open()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing
                Layout.rightMargin: Kirigami.Units.largeSpacing
                height: 2
                color: Kirigami.Theme.textColor
                opacity: 0.2
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Kirigami.Units.smallSpacing

                ListView {
                    id: notesListView
                    model: root.notesModel
                    spacing: Kirigami.Units.largeSpacing
                    clip: true

                    delegate: Kirigami.Card {
                        id: noteCard
                        width: ListView.view.width
                        padding: Kirigami.Units.largeSpacing
                        
                        header: ColumnLayout {
                            spacing: Kirigami.Units.smallSpacing
                            width: parent.width
                            
                            RowLayout {
                                Layout.fillWidth: true
                                
                                PC3.TextField {
                                    id: titleField
                                    Layout.fillWidth: true
                                    font.weight: Font.Medium
                                    placeholderText: "Note Title"
                                    
                                    // Use Binding to avoid binding loop
                                    Binding {
                                        target: titleField
                                        property: "text"
                                        value: model.title === undefined ? "Note " + (index + 1) : model.title
                                        when: !titleField.activeFocus
                                    }
                                    
                                    onTextChanged: if (activeFocus) {
                                        notesModel.setProperty(index, "title", text)
                                        saveNotes()
                                    }
                                }

                                PC3.Button {
                                    icon.name: "edit-delete"
                                    display: PC3.Button.IconOnly
                                    onClicked: {
                                        deleteConfirmDialog.deleteAll = false
                                        deleteConfirmDialog.noteIndex = index
                                        deleteConfirmDialog.open()
                                    }
                                }
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Kirigami.Theme.textColor
                                opacity: 0.2
                            }
                        }

                        contentItem: ColumnLayout {
                            spacing: 0

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.minimumHeight: Kirigami.Units.gridUnit * 5
                                Layout.maximumHeight: notesListView.height - Kirigami.Units.gridUnit * 4
                                visible: model.isEditing
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                                PC3.TextArea {
                                    id: editArea
                                    width: parent.width
                                    text: content
                                    wrapMode: TextEdit.Wrap
                                    
                                    background: Rectangle {
                                        color: Kirigami.Theme.backgroundColor
                                        opacity: 0.5
                                        radius: 3
                                    }
                                    
                                    onTextChanged: {
                                        notesModel.setProperty(index, "content", text)
                                        saveNotes()
                                    }

                                    onActiveFocusChanged: {
                                        if (activeFocus) {
                                            root.activeTextArea = editArea
                                        } else if (root.activeTextArea === editArea) {
                                            root.activeTextArea = null
                                            notesModel.setProperty(index, "isEditing", false)
                                        }
                                    }

                                    Keys.onEscapePressed: {
                                        root.activeTextArea = null
                                        notesModel.setProperty(index, "isEditing", false)
                                        focus = false
                                    }

                                    // Show markdown syntax help
                                    placeholderText: "Write your notes here using Markdown...\n" +
                                                   "# Heading 1\n" +
                                                   "## Heading 2\n\n" +
                                                   "**Bold** or *Italic*\n" +
                                                   "- List item\n" +
                                                   "1. Numbered item\n" +
                                                   "[Link](http://example.com)\n" +
                                                   "`code`"
                                }
                            }

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.minimumHeight: Kirigami.Units.gridUnit * 5
                                Layout.maximumHeight: notesListView.height - Kirigami.Units.gridUnit * 4
                                visible: !model.isEditing
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                                TextEdit {
                                    id: previewArea
                                    width: parent.width
                                    text: content
                                    readOnly: true
                                    wrapMode: TextEdit.Wrap
                                    textFormat: TextEdit.MarkdownText
                                    selectByMouse: true
                                    
                                    color: Kirigami.Theme.textColor
                                    selectedTextColor: Kirigami.Theme.highlightedTextColor
                                    selectionColor: Kirigami.Theme.highlightColor
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton
                                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.IBeamCursor
                                        
                                        onClicked: {
                                            if (parent.hoveredLink) {
                                                Qt.openUrlExternally(parent.hoveredLink)
                                            } else {
                                                notesModel.setProperty(index, "isEditing", true)
                                                editArea.forceActiveFocus()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    add: Transition {
                        NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 200 }
                    }
                    remove: Transition {
                        NumberAnimation { properties: "opacity"; from: 1; to: 0; duration: 200 }
                    }

                    PlasmaExtras.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - (Kirigami.Units.gridUnit * 8)
                        visible: notesModel.count === 0
                        text: "No notes yet"
                        iconName: "accessories-text-editor"
                        explanation: "Click 'New Note' to start writing"
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        loadNotes()
    }

    function saveNotes() {
        let notes = []
        for (let i = 0; i < notesModel.count; i++) {
            let note = notesModel.get(i)
            notes.push({
                title: note.title,
                content: note.content,
                isEditing: note.isEditing
            })
        }
        plasmoid.configuration.notes = JSON.stringify(notes)
    }

    function loadNotes() {
        try {
            notesModel.clear()
            const notes = JSON.parse(plasmoid.configuration.notes || "[]")
            for (let note of notes) {
                if (!note.hasOwnProperty('isEditing')) {
                    note.isEditing = false
                }
                if (!note.hasOwnProperty('title')) {
                    note.title = ""
                }
                notesModel.append(note)
            }
        } catch (e) {
            notesModel.clear()
        }
    }
} 