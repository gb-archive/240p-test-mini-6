;
; Main program for 240p test suite
; Copyright 2018 Damian Yerrick
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License along
; with this program; if not, write to the Free Software Foundation, Inc.,
; 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
;
include "src/hardware.inc"
include "src/global.inc"

section "main_reti", ROM0

; Double-colon these so that the header can see them
timer_handler::
serial_handler::
joypad_handler::
  reti

section "main_jp_hl", ROM0
jp_hl::
  jp hl

section "main", ROM0

main::
  ; Clear GBC high VRAM if necessary
  ld a,[initial_a]
  cp $11
  jr nz,.no_clear_high_nametables
    ldh [rVBK],a
	ld h,$00
	ld de,$9800
	ld bc,$0800
	call memset
    xor a
	ldh [rVBK],a
  .no_clear_high_nametables:
  
  ; Avoid uninitialized read warnings for nmis and cur_keys
  xor a
  ld [nmis],a

  ; Set up vblank handler
  ld a,IEF_VBLANK
  ldh [rIE],a  ; enable IRQs
  xor a
  ldh [rIF],a  ; Acknowledge any pending IRQs
  ei
  call help_init

  if 1
    call activity_credits
  else
    ;call activity_soundtest
    if 1
      ld a,PADF_A|PADF_B|PADF_START|PADF_LEFT|PADF_RIGHT
      ld b,helpsect_to_do
      call helpscreen
    endc
  endc
.loop:
  ld a,PADF_A|PADF_START|PADF_DOWN|PADF_UP|PADF_LEFT|PADF_RIGHT
  ld b,helpsect_144p_test_suite_menu
  call helpscreen

  ; Get the list of handlers for this menu page
  ld de,page_one_handlers
  or a
  jr z,.not_page_two
    ld de,page_two_handlers
  .not_page_two:

  ; Save menu selection and get the index into the handler list
  ld a,[help_wanted_page]
  ld c,a
  ld a,[help_cursor_y]
  ld b,a
  push bc

  ; Start does About instead of what is selected
  ld hl,new_keys
  bit PADB_START,[hl]
  jr z,.not_start
    call activity_about
    jr .skip_activity
  .not_start:

  call de_index_a
  call jp_hl
.skip_activity:

  ; Restore menu selection
  pop bc
  ld a,b
  ld [help_cursor_y],a
  ld a,c
  ld [help_wanted_page],a
  jr .loop

page_one_handlers:
  ; PLUGE, Color bars, Color bleed, and 100 IRE aren't
  ; so relevant without SGB or GBC.
  dw activity_cps_grid
  dw activity_linearity
  dw activity_gray_ramp
  dw activity_solid_screen
  dw activity_motion_blur  ; Replaces "100 IRE"
  dw activity_sharpness
  dw activity_overscan
  dw activity_about
  dw activity_credits

page_two_handlers:
  dw activity_shadow_sprite  ; Integrates "drop shadow" & "stripped"
  dw activity_stopwatch  ; aka "Lag test" in Artemio's
  dw activity_megaton  ; Tell me w/ straight face this isn't Megaton Punch
  dw activity_hillzone_scroll  ; I split these up
  dw activity_kiki_scroll
  dw activity_grid_scroll
  dw activity_full_stripes  ; Integrates "horz. stripes" & "checkerboard"
  dw activity_backlight_zone
  dw activity_soundtest
  dw activity_audiosync
  dw lame_boy_demo
