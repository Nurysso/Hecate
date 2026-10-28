import QtQuick

// Also finishes any add animation it interrupts, otherwise that item freezes mid-fade.
Transition {
    Anim { property: "y" }
    Anim { property: "x"; to: 0 }
    Anim { property: "opacity"; to: 1 }
}
