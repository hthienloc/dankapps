.pragma library

function containsFocus(item) {
    if (!item)
        return false;
    if (item.activeFocus)
        return true;
    return Array.from(item.children || []).some(containsFocus);
}

function focusItem(item, backwards) {
    if (!item || !item.visible || !item.enabled)
        return false;
    if (typeof item.requestFocus === "function") {
        item.requestFocus(backwards);
        return true;
    }
    item.forceActiveFocus(backwards ? Qt.BacktabFocusReason : Qt.TabFocusReason);
    return true;
}

function moveFocus(items, backwards) {
    const targets = items.filter(item => item?.visible && item.enabled);
    const index = targets.findIndex(containsFocus);
    const next = index < 0 ? (backwards ? targets.length - 1 : 0) : index + (backwards ? -1 : 1);
    return focusItem(targets[next], backwards);
}

function handleHorizontalKey(event, items, rtl) {
    if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
        return false;
    switch (event.key) {
    case Qt.Key_Left:
    case Qt.Key_Right:
        moveFocus(items, (event.key === Qt.Key_Left) !== rtl);
        return true;
    }
    return false;
}
