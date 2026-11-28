import QtQuick

Repeater {
    // Delegates of an async Loader arrive over several frames and itemAt() is not observable, so readers depend on revision.
    property int revision: 0
    // A delegate with nested repeaters exposes built.
    readonly property bool built: {
        void revision;
        for (let i = 0; i < count; i++) {
            const item = itemAt(i);
            if (!item || Object(item).built === false)
                return false;
        }
        return true;
    }

    onItemAdded: revision++
    onItemRemoved: revision++
}
