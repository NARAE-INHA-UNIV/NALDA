pragma Singleton
import QtQuick 2.15

QtObject {
    // 새로운 색상을 추가할 때 아래 링크를 참고하세요.
    // 최근 프론트엔드 웹개발에서 널리 사용되는 tailwindcss의 색상 파레트입니다.
    // https://v3.tailwindcss.com/docs/customizing-colors

    // Semantic colors
    readonly property color primary: green
    readonly property color backgroundPrimary: gray900
    readonly property color backgroundSecondary: gray800
    readonly property color backgroundTertiary: gray700
    readonly property color textPrimary: "#dddddd"

    // Color palette
    readonly property color gray100: "#9a9a9a"
    readonly property color gray200: "#8a8a8a"
    readonly property color gray300: "#7a7a7a"
    readonly property color gray400: "#6a6a6a"
    readonly property color gray500: "#5a5a5a"
    readonly property color gray600: "#4a4a4a"
    readonly property color gray700: "#3a3a3a"
    readonly property color gray800: "#2a2a2a"
    readonly property color gray900: "#1a1a1a"

    readonly property color red: "#b91c1c"    // tailwindcss red-700
    readonly property color green: "#15803d"  // tailwindcss green-700

    readonly property color white: "#ffffff"
}
