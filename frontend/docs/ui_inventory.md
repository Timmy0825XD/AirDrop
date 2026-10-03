# Inventario de UI (generado)

> Archivo **generado** por `frontend/tools/ui_inventory.ps1`. No editar
> a mano: correr el script de nuevo despues de cada fase que agregue o
> borre UI. Para que sirve: este listado es el mapa de lo que habra que
> tocar cuando cambie el diseno (pestanas, cajitas, widgets).

Generado: 2026-10-03 08:55

## auth

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `forgot_password_screen.dart` | 117 |
| `login_screen.dart` | 188 |
| `profile_screen.dart` | 93 |
| `register_screen.dart` | 225 |
| `reset_password_screen.dart` | 192 |
| `verify_otp_screen.dart` | 175 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `auth_ambience.dart` | AuthGlow | 21 | ok |
| `auth_ambience.dart` | AuthEntrance | 23 | ok |
| `auth_ambience.dart` | AuthPulsingDot | 10 | ok |
| `auth_ambience.dart` | _AuthPulsingDotState | 25 | ok |
| `auth_page.dart` | AuthPage | 42 | ok |
| `auth_page.dart` | _AuthGlowBackdrop | 15 | ok |
| `auth_top_bar.dart` | AuthTopBar | 45 | ok |
| `document_type_labels.dart` | DocumentTypeLabels | 30 | ok |
| `document_type_tabs.dart` | DocumentTypeTabs | 36 | ok |
| `document_type_tabs.dart` | _DocumentTypeTab | 56 | ok |
| `forgot_header.dart` | ForgotHeader | 36 | ok |
| `forgot_header.dart` | _SecureChip | 32 | ok |
| `forgot_key_badge.dart` | ForgotKeyBadge | 7 | ok |
| `forgot_key_badge.dart` | _ForgotKeyBadgeState | 112 | **>60** |
| `forgot_method_chips.dart` | ForgotMethodChips | 36 | ok |
| `forgot_method_chips.dart` | _MethodChip | 58 | ok |
| `forgot_password_content.dart` | ForgotPasswordContent | 81 | **>60** |
| `forgot_password_content.dart` | _ReturnLink | 41 | ok |
| `login_alert.dart` | LoginAlert | 61 | **>60** |
| `login_backdrop.dart` | LoginBackdrop | 29 | ok |
| `login_backdrop.dart` | _Orb | 37 | ok |
| `login_brand_header.dart` | LoginBrandHeader | 32 | ok |
| `login_brand_header.dart` | _Emblem | 7 | ok |
| `login_brand_header.dart` | _EmblemState | 91 | **>60** |
| `login_button.dart` | LoginButton | 20 | ok |
| `login_button.dart` | _LoginButtonState | 108 | **>60** |
| `login_button.dart` | _Shine | 59 | ok |
| `login_credentials.dart` | LoginCredentials | 57 | ok |
| `login_credentials.dart` | _ForgotLink | 23 | ok |
| `login_credentials.dart` | LoginFieldValidators | 11 | ok |
| `login_field.dart` | LoginField | 30 | ok |
| `login_field.dart` | _LoginFieldState | 106 | **>60** |
| `login_form_alert.dart` | AuthFormAlert | 37 | ok |
| `login_glass_card.dart` | LoginGlassCard | 55 | ok |
| `login_glass_card.dart` | _Gloss | 20 | ok |
| `login_palette.dart` | LoginPalette | 69 | **>60** |
| `login_security_footer.dart` | (sin clases) | 1 | ok |
| `otp_boxes_input.dart` | OtpBoxesInput | 9 | ok |
| `otp_boxes_input.dart` | _OtpBoxesInputState | 73 | **>60** |
| `otp_boxes_input.dart` | _OtpCell | 104 | **>60** |
| `otp_resend_section.dart` | OtpResendSection | 34 | ok |
| `otp_resend_section.dart` | _TimerChip | 46 | ok |
| `otp_resend_section.dart` | _SpinIcon | 9 | ok |
| `otp_resend_section.dart` | _SpinIconState | 21 | ok |
| `otp_shield_badge.dart` | OtpShieldBadge | 7 | ok |
| `otp_shield_badge.dart` | _OtpShieldBadgeState | 71 | **>60** |
| `otp_shield_badge.dart` | _Beacon | 33 | ok |
| `otp_verify_content.dart` | OtpVerifyContent | 64 | **>60** |
| `otp_verify_content.dart` | _Heading | 41 | ok |
| `otp_verify_content.dart` | _Alert | 37 | ok |
| `otp_verify_content.dart` | _SupportRow | 28 | ok |
| `profile_content.dart` | ProfileContent | 84 | **>60** |
| `profile_content.dart` | _ProtocolDivider | 27 | ok |
| `profile_document_editor.dart` | ProfileDocumentEditor | 50 | ok |
| `profile_edit_dialog.dart` | ProfileEditDialog | 18 | ok |
| `profile_edit_dialog.dart` | _ProfileEditDialogState | 95 | **>60** |
| `profile_identity_card.dart` | ProfileIdentityCard | 55 | ok |
| `profile_identity_card.dart` | _Avatar | 61 | **>60** |
| `profile_identity_card.dart` | _RoleBadge | 33 | ok |
| `profile_info_list.dart` | ProfileInfoItem | 15 | ok |
| `profile_info_list.dart` | ProfileInfoList | 50 | ok |
| `profile_info_list.dart` | _InfoRow | 63 | **>60** |
| `profile_labels.dart` | ProfileLabels | 39 | ok |
| `profile_logout_row.dart` | ProfileLogoutRow | 9 | ok |
| `profile_logout_row.dart` | _ProfileLogoutRowState | 40 | ok |
| `profile_logout_row.dart` | _IdleContent | 51 | ok |
| `profile_logout_row.dart` | _BusyContent | 27 | ok |
| `profile_states.dart` | ProfileSignedOut | 56 | ok |
| `profile_states.dart` | ProfileError | 17 | ok |
| `profile_top_bar.dart` | ProfileTopBar | 30 | ok |
| `profile_top_bar.dart` | _BrandLabel | 36 | ok |
| `profile_top_bar.dart` | _SquareButton | 27 | ok |
| `register_consent_row.dart` | RegisterConsentRow | 54 | ok |
| `register_consent_row.dart` | _CheckBox | 29 | ok |
| `register_document_section.dart` | RegisterDocumentSection | 51 | ok |
| `register_field.dart` | RegisterField | 36 | ok |
| `register_field.dart` | _RegisterFieldState | 97 | **>60** |
| `register_fields.dart` | RegisterFields | 122 | **>60** |
| `register_fields.dart` | RegisterFieldValidators | 17 | ok |
| `register_header.dart` | RegisterHeader | 37 | ok |
| `register_header.dart` | RegisterStatusChip | 32 | ok |
| `register_info_banner.dart` | RegisterInfoBanner | 59 | ok |
| `reset_code_header.dart` | ResetCodeHeader | 52 | ok |
| `reset_code_section.dart` | ResetCodeSection | 31 | ok |
| `reset_match_icon.dart` | ResetMatchIcon | 36 | ok |
| `reset_password_form.dart` | ResetPasswordForm | 73 | **>60** |
| `reset_password_form.dart` | _ResetHeading | 59 | ok |
| `reset_password_form.dart` | _Alert | 26 | ok |
| `reset_password_strength.dart` | ResetPasswordStrength | 20 | ok |
| `reset_password_strength.dart` | _StrengthBody | 65 | **>60** |
| `reset_password_strength.dart` | _StrengthBars | 29 | ok |
| `reset_resend_button.dart` | ResetResendButton | 26 | ok |
| `reset_success_view.dart` | ResetSuccessView | 42 | ok |
| `reset_success_view.dart` | _SuccessBadge | 22 | ok |

### Otros (presentation/ sin /widgets)

| Archivo | Lineas |
| --- | --- |
| `auth_controller.dart` | 105 |

## home

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `home_action_card.dart` | HomeActionCard | 58 | ok |
| `home_info_card.dart` | HomeInfoCard | 39 | ok |
| `home_shell.dart` | HomeShell | 57 | ok |
| `home_shell.dart` | _WelcomeHeader | 22 | ok |
| `module_preview.dart` | (sin clases) | 7 | ok |

### Otros (presentation/ sin /widgets)

| Archivo | Lineas |
| --- | --- |
| `admin_home.dart` | 36 |
| `dispatcher_cards.dart` | 54 |
| `dispatcher_home.dart` | 38 |
| `fleet_operator_home.dart` | 36 |
| `requester_home.dart` | 23 |
| `role_home.dart` | 70 |

## hubs

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `hub_detail_screen.dart` | 51 |
| `hub_form_screen.dart` | 65 |
| `hubs_screen.dart` | 136 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `hub_contact_fields.dart` | HubContactFields | 35 | ok |
| `hub_coordinate_fields.dart` | HubCoordinateFields | 43 | ok |
| `hub_detail_content.dart` | HubDetailContent | 62 | **>60** |
| `hub_detail_row.dart` | HubDetailRow | 30 | ok |
| `hub_filter_tabs.dart` | HubFilterTabs | 24 | ok |
| `hub_form_content.dart` | HubFormContent | 46 | ok |
| `hub_form_values.dart` | HubFormValues | 34 | ok |
| `hub_labels.dart` | HubLabels | 16 | ok |
| `hub_location_fields.dart` | HubLocationFields | 54 | ok |
| `hub_status_chip.dart` | HubStatusChip | 29 | ok |
| `hub_tile.dart` | HubTile | 49 | ok |
| `hub_toggle_confirm.dart` | (sin clases) | 38 | ok |

## inventory

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `inventory_form_screen.dart` | 136 |
| `inventory_screen.dart` | 109 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `inventory_chips.dart` | SaleTypeChip | 21 | ok |
| `inventory_chips.dart` | ColdChainChip | 18 | ok |
| `inventory_cold_chain_switch.dart` | InventoryColdChainSwitch | 29 | ok |
| `inventory_delete_confirm.dart` | (sin clases) | 34 | ok |
| `inventory_fields.dart` | InventoryFields | 55 | ok |
| `inventory_form_content.dart` | InventoryFormContent | 53 | ok |
| `inventory_form_values.dart` | InventoryFormValues | 59 | ok |
| `inventory_sale_type_field.dart` | InventorySaleTypeField | 23 | ok |
| `inventory_tile.dart` | InventoryTile | 59 | ok |
| `inventory_tile.dart` | _Marks | 20 | ok |

## users

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `user_form_screen.dart` | 76 |
| `users_screen.dart` | 145 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `hub_multi_select.dart` | HubMultiSelect | 51 | ok |
| `hub_multi_select.dart` | _SingleHubDropdown | 28 | ok |
| `hub_multi_select.dart` | _HubChips | 31 | ok |
| `user_filter_tabs.dart` | UserFilterTabs | 52 | ok |
| `user_form_content.dart` | UserFormContent | 44 | ok |
| `user_form_content_body.dart` | UserFormContentBody | 51 | ok |
| `user_form_values.dart` | UserFormValues | 39 | ok |
| `user_identity_fields.dart` | UserIdentityFields | 50 | ok |
| `user_labels.dart` | UserLabels | 10 | ok |
| `user_role_field.dart` | UserRoleField | 25 | ok |
| `user_status_chip.dart` | UserStatusChip | 31 | ok |
| `user_tile.dart` | UserTile | 47 | ok |
| `user_tile.dart` | _UserTileInfo | 31 | ok |
| `user_toggle_confirm.dart` | (sin clases) | 38 | ok |

## Resumen

- Pantallas (13 archivos): 13
- Archivos de widgets: 80 - clases de widget medidas: 130
- Widgets sobre 60 lineas: 20

Detalle de los que exceden 60 lineas (candidatos a partir):

- auth/forgot_key_badge.dart :: _ForgotKeyBadgeState = 112
- auth/forgot_password_content.dart :: ForgotPasswordContent = 81
- auth/login_alert.dart :: LoginAlert = 61
- auth/login_brand_header.dart :: _EmblemState = 91
- auth/login_button.dart :: _LoginButtonState = 108
- auth/login_field.dart :: _LoginFieldState = 106
- auth/login_palette.dart :: LoginPalette = 69
- auth/otp_boxes_input.dart :: _OtpBoxesInputState = 73
- auth/otp_boxes_input.dart :: _OtpCell = 104
- auth/otp_shield_badge.dart :: _OtpShieldBadgeState = 71
- auth/otp_verify_content.dart :: OtpVerifyContent = 64
- auth/profile_content.dart :: ProfileContent = 84
- auth/profile_edit_dialog.dart :: _ProfileEditDialogState = 95
- auth/profile_identity_card.dart :: _Avatar = 61
- auth/profile_info_list.dart :: _InfoRow = 63
- auth/register_field.dart :: _RegisterFieldState = 97
- auth/register_fields.dart :: RegisterFields = 122
- auth/reset_password_form.dart :: ResetPasswordForm = 73
- auth/reset_password_strength.dart :: _StrengthBody = 65
- hubs/hub_detail_content.dart :: HubDetailContent = 62

