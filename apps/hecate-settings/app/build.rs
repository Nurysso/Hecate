use cxx_qt_build::{CxxQtBuilder, QmlFile, QmlModule};

fn main() {
    CxxQtBuilder::new_qml_module(
        QmlModule::new("com.hecate.settings")
            .qml_file(QmlFile::from("qml/Theme.qml").singleton(true))
            .qml_files([
                "qml/Main.qml",
                "qml/Anim.qml",
                "qml/CAnim.qml",
                "qml/StateLayer.qml",
                "qml/StyledText.qml",
                "qml/Field.qml",
                "qml/Toggle.qml",
                "qml/Slider.qml",
                "qml/ColorField.qml",
                "qml/SettingRow.qml",
                "qml/PillButton.qml",
                "qml/KeybindsPage.qml",
                "qml/CurvesPage.qml",
                "qml/HomePage.qml",
                "qml/MonitorsPage.qml",
                "qml/ConnectivityPage.qml",
            ]),
    )
    .file("src/backend.rs")
    .file("src/connectivity.rs")
    .build();
}
