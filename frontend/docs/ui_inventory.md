# Inventario de UI (generado)

> Archivo **generado** por `frontend/tools/ui_inventory.ps1`. No editar
> a mano: correr el script de nuevo despues de cada fase que agregue o
> borre UI. Para que sirve: este listado es el mapa de lo que habra que
> tocar cuando cambie el diseno (pestanas, cajitas, widgets).

Generado: 2026-11-22 15:56

## analytics

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `analytics_screen.dart` | 219 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `demand_cards.dart` | TopMedicationsCard | 32 | ok |
| `demand_cards.dart` | DemandByDayCard | 37 | ok |
| `demand_cards.dart` | DemandZonesCard | 55 | ok |
| `hub_ranking_card.dart` | HubRankingCard | 41 | ok |
| `kpi_card.dart` | KpiGroupCard | 24 | ok |
| `kpi_card.dart` | KpiRow | 43 | ok |

## auth

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `accept_policy_screen.dart` | 72 |
| `email_change_screen.dart` | 165 |
| `forgot_password_screen.dart` | 139 |
| `login_screen.dart` | 259 |
| `policy_screen.dart` | 36 |
| `prescription_access_screen.dart` | 103 |
| `privacy_screen.dart` | 117 |
| `profile_screen.dart` | 180 |
| `register_screen.dart` | 253 |
| `reset_password_screen.dart` | 268 |
| `verify_otp_screen.dart` | 221 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `airspace_map.dart` | AirspaceMap | 20 | ok |
| `airspace_map.dart` | _AirspaceMapState | 57 | ok |
| `airspace_painter.dart` | AirspaceLook | 46 | ok |
| `airspace_painter.dart` | AirspacePainter | 74 | **>60** |
| `airspace_reveal.dart` | AirspaceReveal | 20 | ok |
| `airspace_reveal.dart` | _AirspaceRevealState | 54 | ok |
| `airspace_reveal.dart` | _CircleClipper | 26 | ok |
| `airspace_traffic.dart` | AirspaceTraffic | 30 | ok |
| `airspace_traffic.dart` | AirspaceFlight | 29 | ok |
| `airspace_traffic.dart` | AirspaceRing | 6 | ok |
| `auth_brand.dart` | AuthHeaderMetrics | 34 | ok |
| `auth_brand.dart` | AuthLogoTile | 11 | ok |
| `auth_brand.dart` | AuthBrandBar | 32 | ok |
| `auth_brand.dart` | AuthPill | 33 | ok |
| `auth_brand.dart` | AuthBackButton | 20 | ok |
| `auth_choice_group.dart` | AuthChoiceGroup | 36 | ok |
| `auth_curved_header.dart` | AuthCurvedHeader | 38 | ok |
| `auth_curved_header.dart` | _CurvedBottomClipper | 15 | ok |
| `auth_curved_header.dart` | _EdgePainter | 32 | ok |
| `auth_curved_header.dart` | _TopVeil | 26 | ok |
| `auth_date_field.dart` | AuthDateField | 49 | ok |
| `auth_date_field.dart` | _DateBox | 52 | ok |
| `auth_form_sheet.dart` | AuthFormSheet | 51 | ok |
| `auth_glass.dart` | AuthChrome | 36 | ok |
| `auth_glass.dart` | AuthSheetPanel | 29 | ok |
| `auth_location_field.dart` | AuthLocationField | 58 | ok |
| `auth_location_field.dart` | _MapPreview | 53 | ok |
| `auth_location_field.dart` | _StillMap | 20 | ok |
| `auth_location_field.dart` | _LocationHeader | 29 | ok |
| `auth_location_field.dart` | _PinLayer | 26 | ok |
| `auth_location_field.dart` | _MapHint | 36 | ok |
| `auth_step_scaffold.dart` | AuthStepScaffold | 32 | ok |
| `auth_step_scaffold.dart` | _AuthStepScaffoldState | 48 | ok |
| `auth_step_scaffold.dart` | _StepLayers | 39 | ok |
| `auth_step_scaffold.dart` | _StepHeader | 31 | ok |
| `auth_step_scaffold.dart` | _StepTopBar | 25 | ok |
| `auth_step_scaffold.dart` | _StepHero | 46 | ok |
| `auth_step_scaffold.dart` | _StepBadge | 38 | ok |
| `auth_step_scaffold.dart` | _StepSheet | 58 | ok |
| `auth_text_link.dart` | AuthTextLink | 30 | ok |
| `dispatcher_profile_page.dart` | DispatcherProfilePage | 36 | ok |
| `dispatcher_profile_page.dart` | _ProfileBody | 54 | ok |
| `dispatcher_profile_page.dart` | _AssignedCentral | 46 | ok |
| `document_type_labels.dart` | DocumentTypeLabels | 34 | ok |
| `document_type_tabs.dart` | DocumentTypeTabs | 54 | ok |
| `document_type_tabs.dart` | _SlidingPill | 21 | ok |
| `document_type_tabs.dart` | _DocumentTypeTab | 36 | ok |
| `email_change_card.dart` | EmailChangeCard | 59 | ok |
| `email_change_card.dart` | _EmailChangeActions | 26 | ok |
| `email_edit_sheet.dart` | EmailEditSheet | 10 | ok |
| `email_edit_sheet.dart` | _EmailEditSheetState | 60 | ok |
| `email_edit_sheet.dart` | _EmailField | 32 | ok |
| `email_edit_sheet.dart` | CurrentPasswordField | 41 | ok |
| `forgot_password_content.dart` | ForgotPasswordForm | 48 | ok |
| `forgot_password_content.dart` | _ForgotHeading | 27 | ok |
| `forgot_password_content.dart` | _CodeLifetime | 30 | ok |
| `forgot_password_content.dart` | ForgotSentCard | 32 | ok |
| `forgot_password_content.dart` | _SentBody | 43 | ok |
| `location_gps_row.dart` | LocationGps | 19 | ok |
| `location_gps_row.dart` | LocationGpsExtras | 26 | ok |
| `location_gps_row.dart` | LocationGpsButton | 28 | ok |
| `location_gps_row.dart` | LocationAccuracyNote | 35 | ok |
| `location_picker.dart` | LocationPickerPage | 16 | ok |
| `location_picker.dart` | _LocationPickerPageState | 45 | ok |
| `location_picker.dart` | _CenterPin | 49 | ok |
| `location_picker.dart` | _Coordinates | 26 | ok |
| `login_alert.dart` | LoginAlert | 60 | ok |
| `login_alert.dart` | _CloseButton | 18 | ok |
| `login_form_alert.dart` | AuthFormAlert | 37 | ok |
| `login_form.dart` | LoginHeading | 26 | ok |
| `login_form.dart` | LoginFields | 48 | ok |
| `login_form.dart` | _PasswordField | 29 | ok |
| `login_form.dart` | LoginActions | 54 | ok |
| `login_intro.dart` | LoginIntro | 35 | ok |
| `login_intro.dart` | _IntroHeader | 38 | ok |
| `login_intro.dart` | _BrandMark | 40 | ok |
| `login_intro.dart` | _Wordmark | 61 | **>60** |
| `login_intro.dart` | _Materialize | 33 | ok |
| `login_intro.dart` | _Tagline | 30 | ok |
| `login_intro.dart` | _SkipHint | 29 | ok |
| `login_intro.dart` | _InThenOut | 30 | ok |
| `login_timeline.dart` | LoginTimeline | 37 | ok |
| `login_timeline.dart` | LoginLayout | 12 | ok |
| `operator_hub_sheet.dart` | (sin clases) | 52 | ok |
| `operator_profile_hubs.dart` | OperatorProfileHubs | 56 | ok |
| `operator_profile_hubs.dart` | _HubsRetryNotice | 19 | ok |
| `operator_profile_page.dart` | OperatorProfilePage | 32 | ok |
| `operator_profile_page.dart` | _OperatorProfileHeader | 24 | ok |
| `operator_profile_page.dart` | _OperatorProfileBody | 50 | ok |
| `operator_profile_page.dart` | _OperatorSignOut | 18 | ok |
| `otp_boxes.dart` | OtpBoxes | 50 | ok |
| `otp_boxes.dart` | _Slot | 27 | ok |
| `otp_boxes.dart` | _OtpBox | 52 | ok |
| `otp_boxes.dart` | _OtpFrame | 42 | ok |
| `otp_boxes.dart` | _Digit | 30 | ok |
| `otp_boxes.dart` | _Caret | 7 | ok |
| `otp_boxes.dart` | _CaretState | 40 | ok |
| `otp_code_field.dart` | OtpCodeField | 22 | ok |
| `otp_code_field.dart` | _OtpCodeFieldState | 58 | ok |
| `otp_resend_card.dart` | OtpResendCard | 47 | ok |
| `otp_resend_card.dart` | _Countdown | 33 | ok |
| `otp_resend_card.dart` | _ResendButton | 31 | ok |
| `otp_resend_card.dart` | _DrainBar | 25 | ok |
| `otp_success_check.dart` | OtpSuccessCheck | 58 | ok |
| `otp_verify_content.dart` | OtpHeading | 42 | ok |
| `otp_verify_content.dart` | OtpStatus | 41 | ok |
| `otp_verify_content.dart` | _Pending | 35 | ok |
| `otp_verify_content.dart` | _Verified | 18 | ok |
| `password_confirm_sheet.dart` | PasswordConfirmSheet | 16 | ok |
| `password_confirm_sheet.dart` | _PasswordConfirmSheetState | 55 | ok |
| `policy_content.dart` | PolicyBody | 22 | ok |
| `policy_content.dart` | PolicyContent | 32 | ok |
| `privacy_cards.dart` | ConsentCard | 37 | ok |
| `privacy_cards.dart` | DataRightsCard | 45 | ok |
| `profile_document_editor.dart` | ProfileDocumentEditor | 41 | ok |
| `profile_edit_sheet.dart` | ProfileEditSheet | 16 | ok |
| `profile_edit_sheet.dart` | _ProfileEditSheetState | 56 | ok |
| `profile_field_type.dart` | (sin clases) | 67 | ok |
| `profile_identity_card.dart` | ProfileIdentityCard | 53 | ok |
| `profile_identity_card.dart` | _Initials | 34 | ok |
| `profile_labels.dart` | ProfileLabels | 24 | ok |
| `profile_legacy_page.dart` | ProfileLegacyPage | 37 | ok |
| `profile_legacy_page.dart` | _ProfileLegacyBlocks | 39 | ok |
| `profile_legacy_page.dart` | _LegacySignOut | 16 | ok |
| `profile_sections.dart` | ProfileDataCard | 49 | ok |
| `profile_sections.dart` | ProfilePendingEmailCard | 46 | ok |
| `profile_sections.dart` | _EditableLine | 51 | ok |
| `profile_sections.dart` | ProfileHubsCard | 27 | ok |
| `profile_session_state.dart` | ProfileSessionState | 37 | ok |
| `register_consent_row.dart` | RegisterConsentRow | 58 | ok |
| `register_consent_row.dart` | _ConsentText | 32 | ok |
| `register_consent_row.dart` | _CheckBox | 32 | ok |
| `register_document_section.dart` | RegisterIdentityFields | 54 | ok |
| `register_fields.dart` | RegisterControllers | 24 | ok |
| `register_fields.dart` | RegisterFormData | 15 | ok |
| `register_fields.dart` | RegisterContactFields | 57 | ok |
| `register_fields.dart` | _CountryCode | 25 | ok |
| `register_header.dart` | RegisterHeaderLayer | 38 | ok |
| `register_header.dart` | RegisterHeading | 24 | ok |
| `register_progress.dart` | RegisterProgress | 40 | ok |
| `register_progress.dart` | _Step | 39 | ok |
| `requester_profile_details.dart` | RequesterProfileDetails | 36 | ok |
| `requester_profile_details.dart` | _DetailsHeader | 24 | ok |
| `requester_profile_details.dart` | _EditableProfileValue | 56 | ok |
| `requester_profile_details.dart` | _AllergyDetails | 31 | ok |
| `requester_profile_group.dart` | RequesterProfileGroup | 21 | ok |
| `requester_profile_group.dart` | _ProfileMenuRow | 29 | ok |
| `requester_profile_group.dart` | _ProfileMenuTexts | 21 | ok |
| `requester_profile_identity.dart` | RequesterProfileIdentity | 41 | ok |
| `requester_profile_identity.dart` | _IdentityDetails | 29 | ok |
| `requester_profile_identity.dart` | _ProfileAvatar | 30 | ok |
| `requester_profile_page.dart` | RequesterProfilePage | 49 | ok |
| `requester_profile_page.dart` | _ProfileHeader | 25 | ok |
| `requester_profile_page.dart` | _SectionTitle | 11 | ok |
| `requester_profile_page.dart` | _SignOutAction | 19 | ok |
| `requester_profile_sections.dart` | RequesterProfileInformation | 37 | ok |
| `requester_profile_sections.dart` | RequesterProfileExperience | 27 | ok |
| `requester_profile_values.dart` | (sin clases) | 1 | ok |
| `reset_code_section.dart` | ResetCodeSection | 57 | ok |
| `reset_match_icon.dart` | ResetMatchIcon | 39 | ok |
| `reset_password_form.dart` | ResetHeading | 41 | ok |
| `reset_password_form.dart` | ResetPasswordFields | 54 | ok |
| `reset_password_form.dart` | _ConfirmField | 26 | ok |
| `reset_password_strength.dart` | PasswordScore | 30 | ok |
| `reset_password_strength.dart` | ResetPasswordStrength | 46 | ok |
| `reset_password_strength.dart` | _Segment | 33 | ok |
| `reset_success_view.dart` | ResetSuccessView | 15 | ok |
| `reset_success_view.dart` | _ResetSuccessViewState | 39 | ok |
| `reset_success_view.dart` | _SuccessLayout | 39 | ok |
| `reset_success_view.dart` | _SuccessTimeline | 25 | ok |
| `reset_success_view.dart` | _ShrinkingHeader | 21 | ok |
| `reset_success_view.dart` | _SuccessSeal | 40 | ok |
| `reset_success_view.dart` | _SealCheck | 37 | ok |
| `reset_success_view.dart` | _OrbitDot | 12 | ok |
| `reset_success_view.dart` | _DashedRing | 25 | ok |
| `reset_success_view.dart` | _SuccessText | 55 | ok |
| `reset_success_view.dart` | _SuccessCopy | 24 | ok |

### Otros (presentation/ sin /widgets)

| Archivo | Lineas |
| --- | --- |
| `auth_controller.dart` | 175 |
| `policy_gate.dart` | 9 |

## delivery

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `receive_order_screen.dart` | 234 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `delivery_code_badge.dart` | DeliveryCodeBadge | 53 | ok |
| `receive_order_button.dart` | ReceiveOrderButton | 25 | ok |
| `receive_order_card.dart` | ReceiveOrderView | 39 | ok |
| `receive_order_card.dart` | ReceiveOrderCard | 47 | ok |
| `receive_order_card.dart` | _DroneKeypad | 41 | ok |
| `transfer_checklist.dart` | TransferChecklist | 47 | ok |

## fleet

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `drone_form_screen.dart` | 140 |
| `drone_maintenance_screen.dart` | 67 |
| `fleet_map_screen.dart` | 86 |
| `fleet_screen.dart` | 192 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `cold_compartment_switch.dart` | ColdCompartmentSwitch | 41 | ok |
| `drone_facts_sheet.dart` | (sin clases) | 80 | ok |
| `drone_form_header.dart` | DroneFormHeader | 12 | ok |
| `drone_form_page.dart` | DroneFormPage | 38 | ok |
| `drone_form_page.dart` | _DroneFormFields | 36 | ok |
| `drone_form_page.dart` | _DroneIdentity | 18 | ok |
| `drone_form_page.dart` | _DroneModelChoice | 21 | ok |
| `drone_form_page.dart` | _DroneEquipment | 29 | ok |
| `drone_form_page.dart` | _PayloadNote | 20 | ok |
| `drone_form_values.dart` | DroneFormValues | 32 | ok |
| `drone_health.dart` | DroneHealth | 44 | ok |
| `drone_health.dart` | _Battery | 28 | ok |
| `drone_health.dart` | _ColdFlag | 22 | ok |
| `drone_identifier_field.dart` | DroneIdentifierField | 33 | ok |
| `drone_identifier_field.dart` | _IdentifierInput | 35 | ok |
| `drone_model_field.dart` | DroneModelField | 51 | ok |
| `drone_model_field.dart` | _ModelOption | 46 | ok |
| `drone_model_field.dart` | _ModelNames | 17 | ok |
| `drone_model_field.dart` | _ModelSelection | 36 | ok |
| `drone_status_chip.dart` | DroneStatusChip | 17 | ok |
| `drone_status_sheet.dart` | DroneStatusSheet | 53 | ok |
| `drone_status_sheet.dart` | _SheetHeader | 79 | **>60** |
| `drone_tile.dart` | DroneTile | 29 | ok |
| `drone_tile.dart` | _DroneHeading | 44 | ok |
| `drone_tile.dart` | _DroneState | 33 | ok |
| `drone_tile.dart` | _DroneDetails | 23 | ok |
| `drone_tile.dart` | _DroneAction | 45 | ok |
| `field_row_separator.dart` | FieldRowSeparator | 10 | ok |
| `fleet_flight_card.dart` | FleetFlightCard | 26 | ok |
| `fleet_flight_card.dart` | _FlightRow | 48 | ok |
| `fleet_flight_card.dart` | _FlightBody | 47 | ok |
| `fleet_flight_card.dart` | _FlightPhase | 36 | ok |
| `fleet_flight_card.dart` | _WatchFlight | 22 | ok |
| `fleet_hub_selector.dart` | FleetHubSelector | 49 | ok |
| `fleet_legal_zone_layer.dart` | FleetLegalZoneLayer | 21 | ok |
| `fleet_list_content.dart` | FleetListContent | 57 | ok |
| `fleet_list_content.dart` | _FleetListState | 48 | ok |
| `fleet_list_content.dart` | _FleetRetryNotice | 12 | ok |
| `fleet_list_header.dart` | FleetListHeader | 58 | ok |
| `fleet_list_page.dart` | FleetListPage | 56 | ok |
| `fleet_list_page.dart` | _SuspendedHubNotice | 12 | ok |
| `fleet_list_values.dart` | FleetListValues | 56 | ok |
| `fleet_live_map.dart` | FleetLiveMap | 57 | ok |
| `fleet_map_header.dart` | FleetMapHeader | 56 | ok |
| `fleet_map_header.dart` | _MapClock | 6 | ok |
| `fleet_map_header.dart` | _MapClockState | 28 | ok |
| `fleet_map_layers.dart` | FleetGeofenceLayer | 25 | ok |
| `fleet_map_layers.dart` | FleetRoutesLayer | 25 | ok |
| `fleet_map_layers.dart` | FleetHubsLayer | 23 | ok |
| `fleet_map_layers.dart` | FleetDronesLayer | 37 | ok |
| `fleet_map_layers.dart` | FleetIncidentsLayer | 25 | ok |
| `fleet_map_markers.dart` | FleetDronePin | 39 | ok |
| `fleet_map_markers.dart` | _DroneLabel | 34 | ok |
| `fleet_map_markers.dart` | FleetHubPin | 52 | ok |
| `fleet_map_page.dart` | FleetMapPage | 20 | ok |
| `fleet_map_page.dart` | _FleetMapPageState | 59 | ok |
| `fleet_map_sheet.dart` | (sin clases) | 80 | ok |
| `fleet_map_values.dart` | FleetMapValues | 68 | **>60** |
| `fleet_summary.dart` | FleetSummary | 33 | ok |
| `fleet_summary.dart` | _Cell | 34 | ok |
| `maintenance_period_tile.dart` | MaintenancePeriodTile | 59 | ok |
| `maintenance_sheet.dart` | MaintenanceSheet | 14 | ok |
| `maintenance_sheet.dart` | _MaintenanceSheetState | 59 | ok |
| `maintenance_sheet.dart` | _MaintenanceFields | 45 | ok |
| `reroute_notice.dart` | (sin clases) | 23 | ok |

## geofences

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `geofence_draw_screen.dart` | 100 |
| `geofence_editor_screen.dart` | 60 |
| `geofence_form_screen.dart` | 100 |
| `geofences_screen.dart` | 58 |
| `legal_zone_form_screen.dart` | 108 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `choice_group.dart` | ChoiceGroup | 42 | ok |
| `geofence_choices.dart` | GeofenceCategoryField | 32 | ok |
| `geofence_choices.dart` | GeofenceExpiryField | 44 | ok |
| `geofence_circle_map.dart` | GeofenceCircleMap | 53 | ok |
| `geofence_delete_confirm.dart` | (sin clases) | 60 | ok |
| `geofence_detail_sheet.dart` | (sin clases) | 41 | ok |
| `geofence_draw_bar.dart` | GeofenceDrawBar | 28 | ok |
| `geofence_draw_bar.dart` | _DrawButtons | 34 | ok |
| `geofence_draw_map.dart` | GeofenceDrawMap | 51 | ok |
| `geofence_draw_map.dart` | _VertexDot | 37 | ok |
| `geofence_draw_map.dart` | _ShapeLayer | 25 | ok |
| `geofence_facts.dart` | GeofenceFacts | 52 | ok |
| `geofence_form_page.dart` | GeofenceFormPage | 58 | ok |
| `geofence_form_page.dart` | _GeofenceSubmitButton | 20 | ok |
| `geofence_form_sheet.dart` | GeofenceFormSheet | 42 | ok |
| `geofence_form_values.dart` | GeofenceFormValues | 62 | **>60** |
| `geofence_history.dart` | GeofenceHistory | 34 | ok |
| `geofence_history.dart` | _ChangeRow | 25 | ok |
| `geofence_list_values.dart` | (sin clases) | 15 | ok |
| `geofence_list.dart` | GeofenceList | 54 | ok |
| `geofence_list.dart` | _GeofenceListState | 35 | ok |
| `geofence_list.dart` | _GeofenceRetry | 25 | ok |
| `geofence_picker_field.dart` | GeofencePickerField | 53 | ok |
| `geofence_picker_field.dart` | _GeofencePickerBox | 40 | ok |
| `geofence_polygon_preview.dart` | GeofencePolygonPreview | 50 | ok |
| `geofence_polygon_preview.dart` | _GeofenceShapeChoices | 22 | ok |
| `geofence_polygon_preview.dart` | _GeofenceMapPreview | 32 | ok |
| `geofence_radius_bar.dart` | GeofenceRadiusBar | 41 | ok |
| `geofence_shape_field.dart` | GeofenceShapeField | 38 | ok |
| `geofence_text_fields.dart` | GeofenceTextFields | 48 | ok |
| `geofence_text_fields.dart` | _GeofenceTextRow | 46 | ok |
| `geofence_text_fields.dart` | _GeofenceTextInput | 37 | ok |
| `geofence_tile_parts.dart` | GeofenceTileInfo | 45 | ok |
| `geofence_tile_parts.dart` | GeofenceStatus | 30 | ok |
| `geofence_tile.dart` | GeofenceTile | 45 | ok |
| `geofence_tile.dart` | _GeofenceTileHeader | 38 | ok |
| `geofence_tile.dart` | _GeofenceTileAction | 23 | ok |
| `geofences_page.dart` | GeofencesPage | 60 | ok |
| `geofences_page.dart` | _GeofencesHeader | 48 | ok |
| `geofences_page.dart` | _LegalZoneHint | 26 | ok |
| `geometry_draft.dart` | GeometryDraft | 57 | ok |
| `legal_zone_actions.dart` | LegalZoneActions | 47 | ok |
| `legal_zone_form_sheet.dart` | LegalZoneFormSheet | 58 | ok |
| `legal_zone_form_values.dart` | LegalZoneFormValues | 76 | **>60** |
| `legal_zone_text_fields.dart` | LegalZoneTextFields | 63 | **>60** |
| `reason_prompt.dart` | (sin clases) | 43 | ok |

## home

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `dispatcher_more_screen.dart` | 43 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `admin_create_sheet.dart` | _CreateOption | 41 | ok |
| `dashboard_period.dart` | DashboardPeriod | 46 | ok |
| `dispatcher_activity.dart` | DispatcherActivity | 59 | ok |
| `dispatcher_activity.dart` | _Counter | 52 | ok |
| `dispatcher_counts.dart` | DispatcherCounts | 41 | ok |
| `dispatcher_home_header.dart` | DispatcherHomeHeader | 45 | ok |
| `dispatcher_home_links.dart` | DispatcherHomeLinks | 45 | ok |
| `dispatcher_home_page.dart` | DispatcherHomePage | 50 | ok |
| `dispatcher_home_page.dart` | DispatcherOperation | 37 | ok |
| `dispatcher_home_values.dart` | DispatcherHomeValues | 70 | **>60** |
| `dispatcher_hub_state.dart` | DispatcherHubState | 33 | ok |
| `dispatcher_more_content.dart` | DispatcherMoreContent | 45 | ok |
| `dispatcher_more_content.dart` | _MoreGroup | 13 | ok |
| `dispatcher_more_items.dart` | (sin clases) | 96 | ok |
| `dispatcher_task_card.dart` | DispatcherTaskCard | 19 | ok |
| `dispatcher_tasks.dart` | DispatcherTasks | 44 | ok |
| `dispatcher_urgent_action.dart` | DispatcherUrgentAction | 31 | ok |
| `first_order_card.dart` | FirstOrderCard | 45 | ok |
| `fleet_health_card.dart` | FleetHealthCard | 51 | ok |
| `fleet_incidents_card.dart` | FleetIncidentsCard | 38 | ok |
| `fleet_usage_card.dart` | FleetUsageCard | 45 | ok |
| `fleet_usage_card.dart` | _StackedBar | 29 | ok |
| `header_add_button.dart` | HeaderAddButton | 21 | ok |
| `home_brand_bar.dart` | HomeBrandBar | 27 | ok |
| `home_grid.dart` | HomeGrid | 24 | ok |
| `home_grid.dart` | HomeLabel | 20 | ok |
| `home_header.dart` | HomeHeader | 49 | ok |
| `home_header.dart` | _Greeting | 30 | ok |
| `home_header.dart` | _Context | 31 | ok |
| `home_header.dart` | _Initials | 38 | ok |
| `home_link.dart` | HomeLink | 46 | ok |
| `home_link.dart` | _LinkText | 17 | ok |
| `home_page.dart` | HomePage | 24 | ok |
| `home_section_heading.dart` | HomeSectionHeading | 26 | ok |
| `home_spotlight.dart` | HomeSpotlight | 49 | ok |
| `home_spotlight.dart` | _Figure | 36 | ok |
| `home_status_card.dart` | HomeStatusCard | 44 | ok |
| `hub_notice.dart` | (sin clases) | 22 | ok |
| `mission_card.dart` | MissionCard | 49 | ok |
| `mission_card.dart` | _Top | 48 | ok |
| `mission_card.dart` | _LiveLabel | 27 | ok |
| `mission_card.dart` | _Eta | 29 | ok |
| `mission_card.dart` | _Footer | 19 | ok |
| `next_delivery_card.dart` | NextDeliveryCard | 60 | ok |
| `next_delivery_card.dart` | _Tag | 21 | ok |
| `next_up.dart` | NextUpItem | 22 | ok |
| `operator_dashboard_details.dart` | (sin clases) | 51 | ok |
| `operator_dashboard.dart` | OperatorDashboard | 40 | ok |
| `operator_empty_card.dart` | OperatorEmptyCard | 38 | ok |
| `operator_empty_card.dart` | _EmptyRoute | 16 | ok |
| `operator_empty_card.dart` | _RouteDashes | 17 | ok |
| `operator_fleet_summary.dart` | OperatorFleetSummary | 57 | ok |
| `operator_fleet_summary.dart` | _FleetCount | 52 | ok |
| `operator_fleet_summary.dart` | _ScopeHeading | 23 | ok |
| `operator_flight_values.dart` | (sin clases) | 24 | ok |
| `operator_flights.dart` | OperatorFlights | 41 | ok |
| `operator_flights.dart` | _FlightState | 28 | ok |
| `operator_flights.dart` | _FlightPreview | 30 | ok |
| `operator_home_content.dart` | OperatorHomeContent | 51 | ok |
| `operator_home_content.dart` | _PeriodHeading | 20 | ok |
| `operator_home_header.dart` | OperatorHomeHeader | 39 | ok |
| `operator_home_page.dart` | OperatorHomePage | 46 | ok |
| `operator_home_page.dart` | _OperatorHubState | 34 | ok |
| `operator_home_values.dart` | OperatorHomeValues | 78 | **>60** |
| `operator_period_summary.dart` | OperatorPeriodSummary | 45 | ok |
| `operator_period_summary.dart` | _MetricRow | 39 | ok |
| `operator_tasks.dart` | OperatorTasks | 39 | ok |
| `operator_tasks.dart` | _ReviewState | 37 | ok |
| `operator_tasks.dart` | _DroneReview | 40 | ok |
| `operator_work_card.dart` | OperatorWorkCard | 38 | ok |
| `operator_work_card.dart` | _WorkIcon | 22 | ok |
| `operator_work_card.dart` | _WorkContent | 47 | ok |
| `operator_work_card.dart` | _WorkTitle | 36 | ok |
| `operator_work_card.dart` | _WorkLabel | 13 | ok |
| `requester_current_order.dart` | RequesterCurrentOrder | 63 | **>60** |
| `requester_current_order.dart` | _OrderHeading | 32 | ok |
| `requester_current_order.dart` | _RouteStrip | 30 | ok |
| `requester_current_order.dart` | _OrderAction | 50 | ok |
| `requester_empty_card.dart` | RequesterEmptyCard | 36 | ok |
| `requester_empty_card.dart` | _EmptyHeading | 46 | ok |
| `requester_empty_card.dart` | _EmptyCorridor | 23 | ok |
| `requester_empty_card.dart` | _Dashes | 21 | ok |
| `requester_home_header.dart` | RequesterHomeHeader | 39 | ok |
| `requester_home_links.dart` | RequesterHomeLinks | 23 | ok |
| `requester_home_orders.dart` | RequesterHomeOrders | 35 | ok |
| `requester_home_orders.dart` | _CurrentOrders | 32 | ok |
| `requester_home_plans.dart` | RequesterHomePlans | 35 | ok |
| `requester_home_plans.dart` | RequesterPlansSummary | 56 | ok |
| `requester_home_plans.dart` | _PlanLink | 22 | ok |
| `requester_home_values.dart` | (sin clases) | 31 | ok |
| `requester_stats.dart` | RequesterStats | 41 | ok |
| `requester_stats.dart` | _DeliveredCard | 47 | ok |
| `requester_stats.dart` | _WeeksCard | 38 | ok |
| `requester_urgent_action.dart` | RequesterUrgentAction | 22 | ok |
| `section_form_page.dart` | SectionFormPage | 37 | ok |
| `section_form_page.dart` | SectionStatePage | 18 | ok |
| `section_header.dart` | SectionHeader | 47 | ok |
| `section_header.dart` | _TitleRow | 27 | ok |
| `section_header.dart` | _Titles | 40 | ok |
| `sign_out.dart` | (sin clases) | 37 | ok |

### Otros (presentation/ sin /widgets)

| Archivo | Lineas |
| --- | --- |
| `admin_home.dart` | 99 |
| `dispatcher_home.dart` | 58 |
| `fleet_operator_home.dart` | 73 |
| `live_mission.dart` | 47 |
| `requester_home.dart` | 51 |
| `role_home.dart` | 71 |

## hubs

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `hub_detail_screen.dart` | 66 |
| `hub_fleet_screen.dart` | 77 |
| `hub_form_screen.dart` | 127 |
| `hubs_screen.dart` | 128 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `hub_actions_sheet.dart` | (sin clases) | 46 | ok |
| `hub_confirm.dart` | _HubSubject | 37 | ok |
| `hub_detail_content.dart` | HubDetailContent | 36 | ok |
| `hub_detail_content.dart` | _HubMap | 36 | ok |
| `hub_detail_sections.dart` | HubDetailIdentity | 47 | ok |
| `hub_detail_sections.dart` | _HubIdentityName | 24 | ok |
| `hub_detail_sections.dart` | _HubStatus | 25 | ok |
| `hub_detail_sections.dart` | HubEnergyRow | 37 | ok |
| `hub_detail_sections.dart` | HubContactSection | 46 | ok |
| `hub_detail_sections.dart` | _HubContactRow | 58 | ok |
| `hub_detail_sections.dart` | _HubContactText | 18 | ok |
| `hub_form_sheet.dart` | HubFormSheet | 53 | ok |
| `hub_form_sheet.dart` | _NameAndType | 40 | ok |
| `hub_form_sheet.dart` | _ContactFields | 43 | ok |
| `hub_form_values.dart` | HubFormValues | 84 | **>60** |
| `hub_labels.dart` | HubLabels | 28 | ok |
| `hub_outage.dart` | HubOutageBanner | 10 | ok |
| `hub_tile.dart` | HubTile | 38 | ok |
| `hub_tile.dart` | HubTypeTile | 21 | ok |
| `hub_tile.dart` | _HubInfo | 41 | ok |
| `hub_type_chips.dart` | HubTypeChips | 34 | ok |

## inventory

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `inventory_form_screen.dart` | 206 |
| `inventory_screen.dart` | 102 |
| `quarantine_screen.dart` | 77 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `inventory_delete_confirm.dart` | _ItemSummary | 28 | ok |
| `inventory_form_page.dart` | InventoryFormPage | 47 | ok |
| `inventory_form_sheet.dart` | InventoryFormSheet | 48 | ok |
| `inventory_form_sheet.dart` | InventoryFormGroup | 24 | ok |
| `inventory_form_values.dart` | InventoryFormValues | 142 | **>60** |
| `inventory_kind_fields.dart` | InventorySaleField | 44 | ok |
| `inventory_kind_fields.dart` | InventoryKindFields | 45 | ok |
| `inventory_kind_fields.dart` | _KindToggle | 49 | ok |
| `inventory_list_content.dart` | InventoryListContent | 58 | ok |
| `inventory_list_content.dart` | _InventoryLoadState | 17 | ok |
| `inventory_list_content.dart` | _InventoryEmpty | 26 | ok |
| `inventory_list_header.dart` | InventoryListHeader | 46 | ok |
| `inventory_list_header.dart` | _InventoryTitle | 36 | ok |
| `inventory_list_header.dart` | _InventorySearch | 24 | ok |
| `inventory_list_page.dart` | InventoryListPage | 56 | ok |
| `inventory_list_values.dart` | (sin clases) | 72 | ok |
| `inventory_results.dart` | InventoryResults | 32 | ok |
| `inventory_stock_fields.dart` | InventoryStockFields | 41 | ok |
| `inventory_stock_fields.dart` | _QuantityAndWeight | 44 | ok |
| `inventory_tile.dart` | InventoryTile | 36 | ok |
| `inventory_tile.dart` | _InventoryDescription | 33 | ok |
| `inventory_tile.dart` | _InventoryFlags | 29 | ok |
| `inventory_tile.dart` | _ColdChainFlag | 19 | ok |
| `inventory_tile.dart` | _InventoryActions | 36 | ok |
| `quarantine_empty_card.dart` | QuarantineEmptyCard | 40 | ok |

## notifications

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `notices_screen.dart` | 127 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `notice_bell.dart` | NoticeBell | 35 | ok |
| `notice_tile.dart` | NoticeTile | 41 | ok |
| `notice_tile.dart` | _NoticeText | 29 | ok |

## onboarding

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `welcome_screen.dart` | 90 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `welcome_page.dart` | WelcomePage | 38 | ok |
| `welcome_progress.dart` | WelcomeProgress | 34 | ok |

### Otros (presentation/ sin /widgets)

| Archivo | Lineas |
| --- | --- |
| `welcome_gate.dart` | 16 |
| `welcome_steps.dart` | 48 |

## orders

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `agenda_screen.dart` | 67 |
| `dispatch_history_screen.dart` | 48 |
| `emergency_screen.dart` | 159 |
| `hub_emergency_screen.dart` | 128 |
| `hub_plan_form_screen.dart` | 161 |
| `in_flight_screen.dart` | 39 |
| `incoming_screen.dart` | 39 |
| `medications_screen.dart` | 133 |
| `order_detail_screen.dart` | 410 |
| `order_history_screen.dart` | 50 |
| `pending_load_screen.dart` | 75 |
| `plan_detail_screen.dart` | 203 |
| `plan_form_screen.dart` | 234 |
| `plan_schedule_screen.dart` | 159 |
| `plans_screen.dart` | 45 |
| `prescription_viewer_screen.dart` | 156 |
| `queue_screen.dart` | 43 |
| `requester_plans_screen.dart` | 60 |
| `scheduled_screen.dart` | 35 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `agenda_content.dart` | AgendaContent | 56 | ok |
| `agenda_content.dart` | _AgendaLoading | 16 | ok |
| `agenda_content.dart` | _AgendaEmpty | 14 | ok |
| `agenda_day_bar.dart` | AgendaDayBar | 30 | ok |
| `agenda_day_bar.dart` | _AgendaDays | 29 | ok |
| `agenda_day_bar.dart` | _DayNavigation | 38 | ok |
| `agenda_day_bar.dart` | _DayButton | 60 | ok |
| `agenda_day_bar.dart` | _DayLabel | 30 | ok |
| `agenda_departure.dart` | AgendaDeparture | 31 | ok |
| `agenda_entry_checks.dart` | AgendaEntryChecks | 37 | ok |
| `agenda_entry_checks.dart` | _Check | 31 | ok |
| `agenda_entry_tile.dart` | AgendaEntryTile | 37 | ok |
| `agenda_entry_tile.dart` | _EntryHeading | 50 | ok |
| `agenda_page.dart` | AgendaPage | 55 | ok |
| `agenda_page.dart` | _AgendaTitle | 25 | ok |
| `agenda_slot_card.dart` | AgendaSlotCard | 31 | ok |
| `agenda_slot_card.dart` | _SlotHeader | 34 | ok |
| `agenda_slot_card.dart` | _SlotTime | 35 | ok |
| `authorize_outcome.dart` | AuthorizeOutcome | 34 | ok |
| `authorize_section.dart` | AuthorizeSection | 60 | ok |
| `authorize_section.dart` | _PrescriptionCheck | 35 | ok |
| `busy_slots.dart` | (sin clases) | 31 | ok |
| `chip_choice_field.dart` | ChipChoiceField | 48 | ok |
| `cold_chain_banner.dart` | ColdChainBanner | 13 | ok |
| `confirm_load_section.dart` | ConfirmLoadSection | 43 | ok |
| `decision_section.dart` | DecisionSection | 9 | ok |
| `decision_section.dart` | _DecisionSectionState | 42 | ok |
| `decision_summary.dart` | (sin clases) | 34 | ok |
| `decline_button.dart` | DeclineButton | 22 | ok |
| `decline_sheet.dart` | DeclineSheet | 7 | ok |
| `decline_sheet.dart` | _DeclineSheetState | 57 | ok |
| `decline_sheet.dart` | _ReasonPills | 29 | ok |
| `dispatcher_flight_route.dart` | DispatcherFlightRoute | 20 | ok |
| `dispatcher_flight_route.dart` | _RouteDashes | 20 | ok |
| `dispatcher_order_alerts.dart` | DispatcherOrderAlerts | 19 | ok |
| `dispatcher_order_card.dart` | DispatcherOrderCard | 39 | ok |
| `dispatcher_order_card.dart` | _MedicationHeading | 41 | ok |
| `dispatcher_order_card.dart` | OrderDetailAction | 24 | ok |
| `dispatcher_permissions.dart` | DispatcherPermissions | 63 | **>60** |
| `emergency_choice_sheet.dart` | _ChoiceSheet | 20 | ok |
| `emergency_choice_sheet.dart` | _ChoiceSheetState | 60 | ok |
| `emergency_choice_sheet.dart` | _ChoiceHeader | 30 | ok |
| `emergency_choice_sheet.dart` | _ChoiceRow | 38 | ok |
| `emergency_destination.dart` | EmergencyDestination | 53 | ok |
| `emergency_destination.dart` | EmergencyDeliveryPoint | 24 | ok |
| `emergency_facts.dart` | EmergencyFacts | 28 | ok |
| `emergency_layout.dart` | EmergencyLayout | 59 | ok |
| `emergency_layout.dart` | EmergencyProgress | 29 | ok |
| `emergency_layout.dart` | EmergencyIntro | 35 | ok |
| `emergency_layout.dart` | EmergencySurface | 15 | ok |
| `emergency_medicine.dart` | EmergencyMedicine | 29 | ok |
| `emergency_medicine.dart` | _MedicationPicker | 48 | ok |
| `emergency_medicine.dart` | _AllergyQuestion | 33 | ok |
| `emergency_medicine.dart` | _DispatcherNote | 24 | ok |
| `emergency_patient.dart` | EmergencyPatient | 56 | ok |
| `emergency_patient.dart` | _PatientChoice | 59 | ok |
| `emergency_patient.dart` | _PatientChoiceMark | 25 | ok |
| `emergency_patient.dart` | _PatientSheet | 8 | ok |
| `emergency_patient.dart` | _PatientSheetState | 56 | ok |
| `emergency_question_row.dart` | EmergencyQuestionRow | 55 | ok |
| `emergency_review.dart` | EmergencyReview | 65 | **>60** |
| `emergency_review.dart` | _ReviewLine | 23 | ok |
| `emergency_situation.dart` | EmergencySituation | 41 | ok |
| `emergency_situation.dart` | _SymptomSummary | 54 | ok |
| `emergency_situation.dart` | _EmergencyNote | 29 | ok |
| `emergency_triage_actions.dart` | (sin clases) | 127 | ok |
| `fallback_card.dart` | FallbackCard | 55 | ok |
| `fallback_card.dart` | FallbackOptionTile | 33 | ok |
| `form_steps.dart` | FormSteps | 41 | ok |
| `form_steps.dart` | _StepBar | 20 | ok |
| `history_page.dart` | HistoryPageView | 60 | ok |
| `history_page.dart` | _HistoryResults | 26 | ok |
| `history_page.dart` | _HistoryFooter | 26 | ok |
| `history_tile.dart` | HistoryTile | 52 | ok |
| `history_values.dart` | (sin clases) | 8 | ok |
| `hub_emergency_fields.dart` | HubEmergencyForm | 26 | ok |
| `hub_emergency_fields.dart` | HubEmergencyFields | 55 | ok |
| `hub_emergency_fields.dart` | _SourcePicker | 60 | ok |
| `hub_emergency_fields.dart` | _HubSourcePlaceholder | 12 | ok |
| `hub_next_delivery.dart` | HubNextDelivery | 55 | ok |
| `hub_next_delivery.dart` | _HubDeliveryHeading | 29 | ok |
| `hub_next_delivery.dart` | _HubDeliveryDate | 33 | ok |
| `hub_next_delivery.dart` | _HubDeliveryDescription | 26 | ok |
| `hub_next_delivery.dart` | _DeliveryLine | 16 | ok |
| `hub_plan_list.dart` | HubPlanList | 19 | ok |
| `hub_plan_list.dart` | _HubPlanRow | 36 | ok |
| `hub_plan_list.dart` | _HubPlanDescription | 29 | ok |
| `hub_plans_overview.dart` | HubPlansOverview | 47 | ok |
| `hub_plans_page.dart` | HubPlansPage | 51 | ok |
| `hub_plans_page.dart` | _HubPlansContent | 51 | ok |
| `hub_plans_page.dart` | _HubPlansState | 25 | ok |
| `hub_request_destination.dart` | HubRequestDestination | 35 | ok |
| `hub_request_fields.dart` | HubRequestFields | 48 | ok |
| `hub_request_fields.dart` | _OriginPicker | 31 | ok |
| `hub_request_fields.dart` | HubQuantityField | 34 | ok |
| `hub_request_fields.dart` | _OfferPicker | 44 | ok |
| `hub_request_fields.dart` | HubTransferNote | 28 | ok |
| `hub_request_fields.dart` | _HubOfferPlaceholder | 12 | ok |
| `hub_request_picker.dart` | HubRequestPicker | 53 | ok |
| `hub_request_picker.dart` | HubSelectBox | 49 | ok |
| `hub_request_picker.dart` | _HubSelectValue | 17 | ok |
| `hub_request_values.dart` | HubRequestValues | 87 | **>60** |
| `hub_schedule_fields.dart` | HubScheduleFields | 40 | ok |
| `hub_schedule_fields.dart` | _HubFrequencyField | 38 | ok |
| `hub_schedule_fields.dart` | _HubScheduleRange | 40 | ok |
| `hub_schedule_preview.dart` | HubSchedulePreview | 40 | ok |
| `hub_trace_tile.dart` | HubTraceTile | 29 | ok |
| `hub_trace_tile.dart` | _DroneRow | 37 | ok |
| `hub_transfer_preview.dart` | HubTransferPreview | 13 | ok |
| `hub_weekdays.dart` | HubWeekdays | 34 | ok |
| `hub_weekdays.dart` | _WeekdayButton | 42 | ok |
| `in_flight_tile.dart` | InFlightTile | 58 | ok |
| `incoming_tile.dart` | IncomingTile | 42 | ok |
| `incoming_tile.dart` | _IncomingStatus | 27 | ok |
| `incoming_tile.dart` | _IncomingRoute | 38 | ok |
| `incoming_tile.dart` | _RouteHubLabel | 13 | ok |
| `load_check_sheet.dart` | LoadCheckSheet | 41 | ok |
| `load_check_sheet.dart` | _CheckRow | 20 | ok |
| `load_check_values.dart` | (sin clases) | 39 | ok |
| `manifest_card.dart` | ManifestCard | 47 | ok |
| `medication_filters.dart` | MedicationFilters | 60 | ok |
| `medication_list.dart` | MedicationList | 48 | ok |
| `medication_rules.dart` | MedicationFilter | 50 | ok |
| `medication_sheet.dart` | MedicationSheet | 51 | ok |
| `medication_tile.dart` | MedicationTile | 66 | **>60** |
| `occurrence_rules.dart` | OccurrenceRules | 45 | ok |
| `occurrence_section.dart` | OccurrenceSection | 51 | ok |
| `occurrence_section.dart` | _OccurrenceActions | 31 | ok |
| `offer_ladder.dart` | OfferLadder | 40 | ok |
| `offer_option.dart` | (sin clases) | 21 | ok |
| `order_assignment_card.dart` | OrderAssignmentCard | 38 | ok |
| `order_fact_row.dart` | OrderFactRow | 42 | ok |
| `order_form_scaffold.dart` | OrderFormScaffold | 35 | ok |
| `order_form_scaffold.dart` | _OrderFormBody | 42 | ok |
| `order_journey.dart` | OrderJourney | 31 | ok |
| `order_journey.dart` | _Track | 40 | ok |
| `order_journey.dart` | _Stop | 48 | ok |
| `order_journey.dart` | _Rail | 19 | ok |
| `order_journey.dart` | _Dot | 38 | ok |
| `order_kind_chip.dart` | OrderKindChip | 15 | ok |
| `order_row_card.dart` | OrderRowCard | 60 | ok |
| `order_row_card.dart` | _OrderCardHeader | 25 | ok |
| `order_status_chip.dart` | OrderStatusChip | 49 | ok |
| `order_summary.dart` | OrderSummary | 58 | ok |
| `order_summary.dart` | _SummaryLines | 59 | ok |
| `order_summary.dart` | _HubLines | 26 | ok |
| `order_tile.dart` | OrderTile | 53 | ok |
| `order_tray.dart` | OrderTray | 47 | ok |
| `order_tray.dart` | _TraySlivers | 46 | ok |
| `patient_fields.dart` | ForWhomField | 31 | ok |
| `patient_fields.dart` | DependentFields | 52 | ok |
| `patient_fields.dart` | AllergiesField | 31 | ok |
| `pending_load_tile.dart` | PendingLoadTile | 36 | ok |
| `pending_load_tile.dart` | _LoadFacts | 40 | ok |
| `pending_load_tile.dart` | _LoadAction | 28 | ok |
| `periodic_calendar_choices.dart` | _MonthDaySheet | 48 | ok |
| `periodic_calendar_days.dart` | PeriodicCalendarDays | 47 | ok |
| `periodic_calendar_range.dart` | PeriodicCalendarRange | 46 | ok |
| `periodic_calendar_range.dart` | PeriodicDateRow | 53 | ok |
| `periodic_calendar.dart` | PeriodicCalendar | 47 | ok |
| `periodic_dates.dart` | PeriodicDates | 42 | ok |
| `periodic_destination.dart` | PeriodicDestination | 44 | ok |
| `periodic_destination.dart` | _PeriodicReview | 29 | ok |
| `periodic_field_row.dart` | PeriodicFieldRow | 59 | ok |
| `periodic_layout.dart` | PeriodicLayout | 29 | ok |
| `periodic_layout.dart` | _PeriodicHeader | 25 | ok |
| `periodic_medicine.dart` | PeriodicMedicine | 34 | ok |
| `periodic_medicine.dart` | _MedicinePicker | 42 | ok |
| `periodic_patient.dart` | PeriodicPatient | 32 | ok |
| `periodic_patient.dart` | _PatientChoice | 59 | ok |
| `periodic_preview.dart` | PeriodicPreview | 45 | ok |
| `periodic_preview.dart` | _PreviewSummary | 34 | ok |
| `periodic_preview.dart` | _OccurrenceLine | 37 | ok |
| `periodic_preview.dart` | _AllDates | 28 | ok |
| `plan_sections.dart` | PlanSummary | 37 | ok |
| `plan_sections.dart` | PlanOccurrences | 30 | ok |
| `plan_sections.dart` | _OccurrenceRow | 54 | ok |
| `plan_tile.dart` | PlanTile | 35 | ok |
| `prescription_checklist.dart` | PrescriptionChecklist | 24 | ok |
| `prescription_image_page.dart` | PrescriptionImagePage | 14 | ok |
| `prescription_image_page.dart` | _PrescriptionImagePageState | 51 | ok |
| `prescription_image_page.dart` | _BrokenImage | 17 | ok |
| `prescription_pages_bar.dart` | PrescriptionPagesBar | 53 | ok |
| `prescription_pdf_page.dart` | PrescriptionPdfPage | 26 | ok |
| `prescription_picker.dart` | PrescriptionPicker | 52 | ok |
| `prescription_picker.dart` | _PatientLine | 25 | ok |
| `prescription_picker.dart` | PrescriptionFileTile | 41 | ok |
| `prescription_picker.dart` | _Thumbnail | 31 | ok |
| `prescription_picker.dart` | PrescriptionButtons | 52 | ok |
| `prescription_record_card.dart` | PrescriptionRecordCard | 35 | ok |
| `queue_content.dart` | QueueContent | 37 | ok |
| `queue_content.dart` | _QueueLoading | 19 | ok |
| `queue_content.dart` | _QueueState | 23 | ok |
| `queue_facts.dart` | QueueFacts | 40 | ok |
| `queue_facts.dart` | QueueFact | 34 | ok |
| `queue_indicators.dart` | QueueIndicators | 28 | ok |
| `queue_list.dart` | QueueList | 35 | ok |
| `queue_list.dart` | _QueueListHeading | 48 | ok |
| `queue_page.dart` | QueuePage | 56 | ok |
| `queue_page.dart` | _QueueTitle | 18 | ok |
| `queue_tile.dart` | QueueTile | 51 | ok |
| `queue_tile.dart` | _QueueReviewButton | 19 | ok |
| `queue_wait.dart` | (sin clases) | 21 | ok |
| `reject_section.dart` | RejectSection | 25 | ok |
| `reject_section.dart` | _RejectSectionState | 54 | ok |
| `requester_delivery_actions.dart` | RequesterDeliveryActions | 58 | ok |
| `requester_delivery_steps.dart` | RequesterDeliverySteps | 24 | ok |
| `requester_delivery_steps.dart` | _DeliveryStep | 62 | **>60** |
| `requester_delivery_steps.dart` | _StepMark | 36 | ok |
| `requester_delivery_summary.dart` | RequesterDeliverySummary | 28 | ok |
| `requester_delivery_summary.dart` | _DeliveryDate | 43 | ok |
| `requester_delivery_summary.dart` | _DeliveryDescription | 27 | ok |
| `requester_next_delivery.dart` | RequesterNextDelivery | 26 | ok |
| `requester_order_actions.dart` | RequesterOrderActions | 38 | ok |
| `requester_order_actions.dart` | _FlightButtons | 45 | ok |
| `requester_order_card.dart` | RequesterOrderCard | 27 | ok |
| `requester_order_card.dart` | _OrderCardBody | 55 | ok |
| `requester_order_display.dart` | (sin clases) | 36 | ok |
| `requester_order_fields.dart` | RequesterOrderForm | 33 | ok |
| `requester_order_fields.dart` | CatalogChoices | 34 | ok |
| `requester_order_fields.dart` | PrescriptionSlot | 32 | ok |
| `requester_order_fields.dart` | DestinationFields | 46 | ok |
| `requester_order_fields.dart` | ClearSpotNote | 26 | ok |
| `requester_order_fields.dart` | PlanQuantityField | 18 | ok |
| `requester_order_heading.dart` | RequesterOrderHeading | 47 | ok |
| `requester_order_heading.dart` | _OrderStatusLine | 27 | ok |
| `requester_order_state.dart` | (sin clases) | 149 | ok |
| `requester_order_values.dart` | RequesterOrderValues | 102 | **>60** |
| `requester_orders_header.dart` | RequesterOrdersHeader | 53 | ok |
| `requester_orders_header.dart` | _OrdersTitle | 25 | ok |
| `requester_orders_header.dart` | _OrderFilters | 43 | ok |
| `requester_orders_page.dart` | RequesterOrdersPage | 17 | ok |
| `requester_orders_page.dart` | _RequesterOrdersPageState | 43 | ok |
| `requester_orders_results.dart` | RequesterOrdersResults | 54 | ok |
| `requester_orders_results.dart` | _OrderList | 32 | ok |
| `requester_plan_list.dart` | RequesterPlanList | 30 | ok |
| `requester_plan_list.dart` | _PlanRow | 28 | ok |
| `requester_plan_list.dart` | _PlanDescription | 28 | ok |
| `requester_plans_content.dart` | RequesterPlansContent | 47 | ok |
| `requester_plans_empty.dart` | RequesterPlansEmpty | 35 | ok |
| `requester_plans_next.dart` | RequesterPlansNext | 51 | ok |
| `requester_plans_next.dart` | _NextNotice | 26 | ok |
| `requester_plans_page.dart` | RequesterPlansPage | 25 | ok |
| `requester_plans_page.dart` | _PlansTitle | 27 | ok |
| `requester_plans_values.dart` | RequesterPlanDelivery | 68 | **>60** |
| `reschedule_sheet.dart` | RescheduleSheet | 10 | ok |
| `reschedule_sheet.dart` | _RescheduleSheetState | 48 | ok |
| `return_check_section.dart` | ReturnCheckSection | 52 | ok |
| `schedule_chip.dart` | ScheduleChip | 35 | ok |
| `schedule_fields.dart` | ScheduleForm | 22 | ok |
| `schedule_fields.dart` | ScheduleFields | 43 | ok |
| `schedule_fields.dart` | ScheduleTimeField | 36 | ok |
| `schedule_fields.dart` | _PrescriptionValidity | 40 | ok |
| `schedule_kind_fields.dart` | ScheduleKindFields | 25 | ok |
| `schedule_kind_fields.dart` | _WeeklyFields | 53 | ok |
| `schedule_kind_fields.dart` | _MonthlyFields | 38 | ok |
| `schedule_kind_fields.dart` | _DatesFields | 45 | ok |
| `schedule_preview_card.dart` | SchedulePreviewCard | 39 | ok |
| `schedule_preview_card.dart` | _PreviewList | 43 | ok |
| `schedule_preview_state.dart` | (sin clases) | 81 | ok |
| `schedule_range_fields.dart` | ScheduleRangeFields | 36 | ok |
| `schedule_range_fields.dart` | ScheduleEndFields | 58 | ok |
| `schedule_values.dart` | ScheduleDraft | 90 | **>60** |
| `scheduled_tile.dart` | ScheduledTile | 28 | ok |
| `scheduled_tile.dart` | _ScheduledCard | 49 | ok |
| `scheduled_values.dart` | (sin clases) | 9 | ok |
| `status_reason_banner.dart` | StatusReasonBanner | 13 | ok |
| `transfer_map.dart` | TransferMap | 47 | ok |
| `transfer_map.dart` | _TransferLayer | 41 | ok |
| `tray_content.dart` | TrayContent | 45 | ok |
| `tray_content.dart` | _KnownTrayContent | 35 | ok |
| `tray_content.dart` | _TrayList | 35 | ok |
| `triage_card.dart` | TriageCard | 53 | ok |
| `triage_card.dart` | AlarmLine | 32 | ok |
| `triage_fields.dart` | TriageForm | 20 | ok |
| `triage_fields.dart` | RedFlagsField | 34 | ok |
| `triage_fields.dart` | AlarmCallCard | 38 | ok |
| `triage_fields.dart` | PatientGroupField | 34 | ok |
| `triage_fields.dart` | SymptomFields | 45 | ok |
| `triage_values.dart` | TriageDraft | 144 | **>60** |
| `watch_flight_button.dart` | WatchFlightButton | 23 | ok |

### Otros (presentation/ sin /widgets)

| Archivo | Lineas |
| --- | --- |
| `order_format.dart` | 126 |

## settings

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `settings_screen.dart` | 40 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `settings_actions.dart` | SettingsActions | 14 | ok |
| `settings_page.dart` | SettingsPage | 51 | ok |
| `settings_reading.dart` | SettingsReading | 36 | ok |
| `settings_sections.dart` | SettingsSections | 44 | ok |
| `settings_sections.dart` | SettingsBlock | 28 | ok |
| `settings_sections.dart` | _TextSizeChoice | 25 | ok |
| `settings_switch.dart` | SettingsSwitch | 29 | ok |
| `theme_picker.dart` | ThemePicker | 53 | ok |
| `theme_picker.dart` | _ThemeOptions | 27 | ok |
| `theme_preview.dart` | ThemeOption | 58 | ok |
| `theme_preview.dart` | ThemePreview | 26 | ok |
| `theme_preview.dart` | _Mini | 57 | ok |

### Otros (presentation/ sin /widgets)

| Archivo | Lineas |
| --- | --- |
| `settings_scope.dart` | 40 |

## tracking

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `tracking_screen.dart` | 217 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `flight_card.dart` | FlightCard | 59 | ok |
| `flight_card.dart` | _Headline | 47 | ok |
| `flight_card.dart` | _Progress | 31 | ok |
| `flight_card.dart` | _Rows | 25 | ok |
| `flight_card.dart` | _Row | 36 | ok |
| `flight_hud.dart` | FlightLiveBar | 57 | ok |
| `flight_hud.dart` | _LiveDot | 14 | ok |
| `flight_map.dart` | FlightMap | 59 | ok |
| `flight_map.dart` | _DroneLayer | 30 | ok |
| `flight_map.dart` | _EndpointsLayer | 29 | ok |
| `flight_map.dart` | _RouteLayer | 49 | ok |
| `flight_notice.dart` | FlightNotice | 34 | ok |
| `flight_timeline.dart` | FlightTimeline | 27 | ok |
| `flight_timeline.dart` | _StepRow | 47 | ok |
| `flight_timeline.dart` | _Rail | 50 | ok |

### Otros (presentation/ sin /widgets)

| Archivo | Lineas |
| --- | --- |
| `flight_moment.dart` | 52 |

## users

### Pantallas

| Archivo | Lineas |
| --- | --- |
| `user_form_screen.dart` | 111 |
| `users_screen.dart` | 139 |

### Widgets

| Archivo | Widget/clase | Lineas | Estado |
| --- | --- | --- | --- |
| `hub_picker.dart` | HubPicker | 48 | ok |
| `hub_picker.dart` | _PickerHeader | 23 | ok |
| `hub_picker.dart` | _NoHubs | 31 | ok |
| `role_cards.dart` | RoleCards | 26 | ok |
| `role_cards.dart` | _RoleCard | 41 | ok |
| `role_cards.dart` | _RoleFace | 38 | ok |
| `user_confirm.dart` | _UserSubject | 38 | ok |
| `user_form_sheet.dart` | UserFormSheet | 58 | ok |
| `user_form_sheet.dart` | _PasswordField | 15 | ok |
| `user_form_sheet.dart` | _PasswordFieldState | 28 | ok |
| `user_form_sheet.dart` | _IdentityFields | 31 | ok |
| `user_form_sheet.dart` | _ContactRow | 43 | ok |
| `user_form_values.dart` | UserFormValues | 74 | **>60** |
| `user_labels.dart` | UserLabels | 36 | ok |
| `user_status_filter.dart` | UserStatusFilter | 32 | ok |
| `user_tile.dart` | UserTile | 35 | ok |
| `user_tile.dart` | UserAvatar | 28 | ok |
| `user_tile.dart` | _UserInfo | 56 | ok |
| `user_tile.dart` | _HubChip | 24 | ok |

## Resumen

- Pantallas (55 archivos): 55
- Archivos de widgets: 370 - clases de widget medidas: 749
- Widgets sobre 60 lineas: 22

Detalle de los que exceden 60 lineas (candidatos a partir):

- auth/airspace_painter.dart :: AirspacePainter = 74
- auth/login_intro.dart :: _Wordmark = 61
- fleet/drone_status_sheet.dart :: _SheetHeader = 79
- fleet/fleet_map_values.dart :: FleetMapValues = 68
- geofences/geofence_form_values.dart :: GeofenceFormValues = 62
- geofences/legal_zone_form_values.dart :: LegalZoneFormValues = 76
- geofences/legal_zone_text_fields.dart :: LegalZoneTextFields = 63
- home/dispatcher_home_values.dart :: DispatcherHomeValues = 70
- home/operator_home_values.dart :: OperatorHomeValues = 78
- home/requester_current_order.dart :: RequesterCurrentOrder = 63
- hubs/hub_form_values.dart :: HubFormValues = 84
- inventory/inventory_form_values.dart :: InventoryFormValues = 142
- orders/dispatcher_permissions.dart :: DispatcherPermissions = 63
- orders/emergency_review.dart :: EmergencyReview = 65
- orders/hub_request_values.dart :: HubRequestValues = 87
- orders/medication_tile.dart :: MedicationTile = 66
- orders/requester_delivery_steps.dart :: _DeliveryStep = 62
- orders/requester_order_values.dart :: RequesterOrderValues = 102
- orders/requester_plans_values.dart :: RequesterPlanDelivery = 68
- orders/schedule_values.dart :: ScheduleDraft = 90
- orders/triage_values.dart :: TriageDraft = 144
- users/user_form_values.dart :: UserFormValues = 74

