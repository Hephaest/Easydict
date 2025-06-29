//
//  GeneralTab.swift
//  Easydict
//
//  Created by Kyle on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import LaunchAtLogin
import SwiftUI

// MARK: - GeneralTab

struct GeneralTab: View {
    // MARK: Internal

    class CheckUpdaterViewModel: ObservableObject {
        // MARK: Lifecycle

        init() {
            updater
                .publisher(for: \.automaticallyChecksForUpdates)
                .assign(to: &$autoChecksForUpdates)
        }

        // MARK: Internal

        @Published var autoChecksForUpdates = true {
            didSet {
                updater.automaticallyChecksForUpdates = autoChecksForUpdates
            }
        }

        // MARK: Private

        private let updater = Configuration.shared.updater
    }

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Form {
            Section {
                FirstAndSecondLanguageSettingView()
                Picker(
                    "setting.general.language.language_detect_optimize",
                    selection: $languageDetectOptimize
                ) {
                    ForEach(LanguageDetectOptimize.allCases, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }
            } header: {
                Text("setting.general.query_language.header")
            }

            Section {
                Toggle("clear_input_when_translating", isOn: $clearInput)
                Toggle(
                    "keep_prev_result_when_selected_text_is_empty", isOn: $keepPrevResultWhenEmpty
                )
                Toggle(
                    "select_query_text_when_window_activate",
                    isOn: $selectQueryTextWhenWindowActivate
                )
            } header: {
                Text("setting.general.input.header")
            }

            Section {
                Toggle("auto_query_ocr_text", isOn: $autoQueryOCRText)
                Toggle("auto_query_selected_text", isOn: $autoQuerySelectedText)
                Toggle("auto_query_pasted_text", isOn: $autoQueryPastedText)
                Toggle("setting.general.voice.auto_play_word_audio", isOn: $autoPlayAudio)
                Picker(
                    "setting.general.voice.english_pronunciation",
                    selection: $pronunciation
                ) {
                    ForEach(EnglishPronunciation.allCases, id: \.rawValue) { option in
                        Text(option.localizedStringResource)
                            .tag(option)
                    }
                }
            } header: {
                Text("setting.general.auto_query.header")
            }

            Section {
                Toggle("auto_copy_ocr_text", isOn: $autoCopyOCRText)
                Toggle("auto_copy_selected_text", isOn: $autoCopySelectedText)
                Toggle("auto_copy_first_translated_text", isOn: $autoCopyFirstTranslatedText)
            } header: {
                Text("setting.general.auto_copy.header")
            }

            Section {
                Toggle("show_google_quick_link", isOn: $showGoogleQuickLink)
                Toggle("show_eudic_quick_link", isOn: $showEudicQuickLink)
                Toggle("show_apple_dictionary_quick_link", isOn: $showAppleDictionaryQuickLink)
                Toggle("show_setting_quick_link", isOn: $showQuickActionButton)
            } header: {
                Text("setting.general.quick_link.header")
            }

            Section {
                Picker("setting.general.language", selection: $languageState.language) {
                    ForEach(LanguageState.LanguageType.allCases, id: \.rawValue) { language in
                        Text(language.name)
                            .tag(language)
                    }
                }
                Picker(
                    "setting.general.appearance.light_dark_appearance", selection: $appearanceType
                ) {
                    ForEach(AppearenceType.allCases, id: \.rawValue) { option in
                        Text(option.title)
                            .tag(option)
                    }
                }

                // Check for updates
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("check_for_updates")
                        Text("lastest_version \(lastestVersion ?? version)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("check_now") {
                        Configuration.shared.updater.checkForUpdates()
                    }
                }

                Toggle(isOn: $checkUpdaterViewModel.autoChecksForUpdates) {
                    Text("auto_check_update ")
                }

                LaunchAtLogin.Toggle {
                    Text("launch_at_startup")
                }
                .onChange(of: LaunchAtLogin.isEnabled) { newValue in
                    logSettings(["launch_at_startup": newValue])
                }

                Toggle(
                    isOn: $hideMenuBarIcon.didSet(execute: { state in
                        if state {
                            // user is not set input shortcut and selection shortcut not allow hide menu bar
                            if !shortcutsHaveSetuped {
                                Defaults[.hideMenuBarIcon] = false
                                showRefuseAlert = true
                            } else {
                                showHideMenuBarIconAlert = true
                            }
                        }
                    })
                ) {
                    Text("hide_menu_bar_icon")
                }
                Picker(
                    "modify_menubar_icon",
                    selection: $selectedMenuBarIcon
                ) {
                    ForEach(MenuBarIconType.allCases) { option in
                        Image(option.rawValue)
                            .renderingMode(.template)
                            .foregroundStyle(.primary)
                    }
                }

            } header: {
                Text("setting.general.app_setting.header")
            }

            Section {
                let bindingFontSize = Binding<Double>(
                    get: {
                        Double(fontSizeOptionIndex)
                    },
                    set: { newValue in
                        fontSizeOptionIndex = UInt(newValue)
                    }
                )
                Slider(value: bindingFontSize, in: 0.0 ... 4.0, step: 1) {
                    Text("setting.general.font.font_size.label")
                } minimumValueLabel: {
                    Text("small")
                        .font(.system(size: 10))
                } maximumValueLabel: {
                    Text("large")
                        .font(.system(size: 14))
                }
            } header: {
                Text("setting.general.font.header")
            } footer: {
                Text("hints_keyboard_shortcuts_font_size")
                    .font(.footnote)
            }
        }
        .formStyle(.grouped)
        .task {
            lastestVersion = await fetchRepoLatestVersion(EZGithubRepoEasydict)
        }
        .alert("hide_menu_bar_icon", isPresented: $showRefuseAlert) {
            Button("ok") {
                showRefuseAlert = false
            }
        } message: {
            Text("refuse_hide_menu_bar_icon_msg")
        }
        .alert("hide_menu_bar_icon", isPresented: $showHideMenuBarIconAlert) {
            HStack {
                Button("ok") {
                    showHideMenuBarIconAlert = false
                }
                Button("cancel") {
                    Defaults[.hideMenuBarIcon] = false
                }
            }
        } message: {
            Text("hide_menu_bar_icon_msg")
        }
    }

    // MARK: Private

    // Query language
    @Default(.languageDetectOptimize) private var languageDetectOptimize

    // Input textfield
    @Default(.clearQueryWhenInputTranslate) private var clearInput
    @Default(.keepPrevResultWhenSelectTranslateTextIsEmpty) private var keepPrevResultWhenEmpty
    @Default(.selectQueryTextWhenWindowActivate) private var selectQueryTextWhenWindowActivate

    // Auto query
    @Default(.autoQueryOCRText) private var autoQueryOCRText
    @Default(.autoQuerySelectedText) private var autoQuerySelectedText
    @Default(.autoQueryPastedText) private var autoQueryPastedText
    @Default(.autoPlayAudio) private var autoPlayAudio
    @Default(.pronunciation) private var pronunciation

    // Auto copy
    @Default(.autoCopyOCRText) private var autoCopyOCRText
    @Default(.autoCopySelectedText) private var autoCopySelectedText
    @Default(.autoCopyFirstTranslatedText) private var autoCopyFirstTranslatedText

    // Quick link
    @Default(.showGoogleQuickLink) private var showGoogleQuickLink
    @Default(.showEudicQuickLink) private var showEudicQuickLink
    @Default(.showAppleDictionaryQuickLink) private var showAppleDictionaryQuickLink
    @Default(.showQuickActionButton) private var showQuickActionButton

    // App setting
    @EnvironmentObject private var languageState: LanguageState
    @Default(.appearanceType) private var appearanceType
    @Default(.hideMenuBarIcon) private var hideMenuBarIcon
    @Default(.selectedMenuBarIcon) private var selectedMenuBarIcon
    @Default(.fontSizeOptionIndex) private var fontSizeOptionIndex

    @State private var showRefuseAlert = false
    @State private var showHideMenuBarIconAlert = false

    @StateObject private var checkUpdaterViewModel = CheckUpdaterViewModel()

    @State private var lastestVersion: String?

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    private var shortcutsHaveSetuped: Bool {
        Defaults[.inputShortcut] != nil || Defaults[.selectionShortcut] != nil
    }

    private func logSettings(_ parameters: [String: Any]) {
        EZLog.logEvent(withName: "settings", parameters: parameters)
    }
}

#Preview {
    GeneralTab()
}

// MARK: - FirstAndSecondLanguageSettingView

private struct FirstAndSecondLanguageSettingView: View {
    // MARK: Internal

    var body: some View {
        Group {
            Picker("setting.general.language.first_language", selection: $firstLanguage) {
                ForEach(Language.allAvailableOptions, id: \.rawValue) { option in
                    Text(verbatim: "\(option.flagEmoji) \(option.localizedName)")
                        .tag(option)
                }
            }
            Picker("setting.general.language.second_language", selection: $secondLanguage) {
                ForEach(Language.allAvailableOptions, id: \.rawValue) { option in
                    Text(verbatim: "\(option.flagEmoji) \(option.localizedName)")
                        .tag(option)
                }
            }
        }
        .onChange(of: firstLanguage) { [firstLanguage] newValue in
            let oldValue = firstLanguage
            if newValue == secondLanguage {
                secondLanguage = oldValue
                languageDuplicatedAlert = .init(
                    duplicatedLanguage: newValue, setField: .second, setLanguage: oldValue
                )
            }
        }
        .onChange(of: secondLanguage) { [secondLanguage] newValue in
            let oldValue = secondLanguage
            if newValue == firstLanguage {
                firstLanguage = oldValue
                languageDuplicatedAlert = .init(
                    duplicatedLanguage: newValue, setField: .first, setLanguage: oldValue
                )
            }
        }
        .alert(
            "setting.general.language.duplicated_alert.title",
            isPresented: showLanguageDuplicatedAlert,
            presenting: languageDuplicatedAlert
        ) { _ in
        } message: { alert in
            Text(alert.description)
        }
    }

    // MARK: Private

    private struct LanguageDuplicateAlert: CustomStringConvertible {
        enum Field: CustomLocalizedStringResourceConvertible {
            case first
            case second

            // MARK: Internal

            var localizedStringResource: LocalizedStringResource {
                switch self {
                case .first:
                    "setting.general.language.duplicated_alert.field.first"
                case .second:
                    "setting.general.language.duplicated_alert.field.second"
                }
            }
        }

        let duplicatedLanguage: Language

        let setField: Field

        let setLanguage: Language

        var description: String {
            // First language should not be same as second language. (\(duplicatedLanguage))
            // \(setField) is replaced with \(setLanguage).
            String(
                localized:
                "setting.general.language.duplicated_alert \(duplicatedLanguage.localizedName)\(String(localized: setField.localizedStringResource))\(setLanguage.localizedName)"
            )
        }
    }

    @Default(.firstLanguage) private var firstLanguage
    @Default(.secondLanguage) private var secondLanguage

    @State private var languageDuplicatedAlert: LanguageDuplicateAlert?

    private var showLanguageDuplicatedAlert: Binding<Bool> {
        .init {
            languageDuplicatedAlert != nil
        } set: { newValue in
            if !newValue {
                languageDuplicatedAlert = nil
            }
        }
    }
}
