;=============================================================================
; Title:        Pseudo Random Number Generator implementation library.
; Algorithm:    Linear Feedback Shift Register (LFSR) 16-bit.
; Filename:     a2k6algo-rnd1.s
; Platform:     Atari 2600 / 65XX
; Language:     65XX Assembly Language (https://cc65.github.io/doc/ca65.html)
; Author:       Justin Lane (atari2600@jigglesoft.co.uk)
; Date:         2021-01-02 20:31
; Version:      2.0.0
; Note:         Ported from Microchip PIC8 implementation.
;-----------------------------------------------------------------------------
; Copyright (c) 2021 Justin Lane
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;     http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
;-----------------------------------------------------------------------------
; Pseudo Random Number Generator - Linear Feedback Shift Register (LFSR) 16-bit.
;
; CA65 Assembler - 65XX CPU.
;
; Usage example 1:-
;           ; Initialise the random library
;           JSR             rnd_init
;           ; Set the 16-bit seed value using the macro (will be fixed)
;           RND1_SET_SEED   $ACE1
;           ; Get a single bit (low bit of W SFR)
;           RND1_GET_BIT
;           JSR             rnd_get_bit
;           ; Get a nybble (low 4 bits of W SFR)
;           RND1_GET_BITS   4
;           movlw           4
;           call            rnd_get_bits
;           ; Get a byte (W SFR)
;           call            rnd_get_byte
;
; Usage example 2:-
;           ; Select the random libraries data bank
;           RND_BANKSEL
;           ; Initialise the random library
;           call            rnd_init
;           ; Set the 16-bit seed value using code
;           movlw           X'00'
;           movwf           rndsr_hi
;           movlw           X'00'
;           movwf           rndsr_lo
;           ; Fix the seed if necessary (zero)
;           call            rnd_fix_seed
;           ; Get a single bit (low bit of W SFR)
;           call            rnd_get_bit
;           ; Get a nybble (low 4 bits of W SFR)
;           movlw           4
;           call            rnd_get_bits
;           ; Get a byte (W SFR)
;           call            rnd_get_byte
;
; Feedback (F) is calculated with the taps on rnd_sr_lo bits 0, 2, 3, 5.
; rnd_sr_lo is shifted right and value shifted out of bit 0 is the output stream.
; rnd_sr_hi is shifted right and the value shifted out of bit 0 goes into bit 7
; of rnd_sr_hi. The feedback becomes bit 7 of rndval_hi.
;
; rnd_sr_hi                            rnd_sr_lo
; | 7 | 6 | 5 | 4 | 3 | 2 |  1 |  0 |->| 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |->| O |
;   ^                                            |       |   |       |      u
;   |                                            |       |    \     /       t
;   |                                            |       |      XOR         p
;   |                                            |       |       |          u
;   |                                            |      XOR------           t
;   |                                            |       |
; | F |<----------------------------------------XOR------
; Feedback
;
; Get bits will take the lowest n bits from rndval_lo and then run the feedback
; and shift process n times.
; Note that the bits taken will be returned will start population of the
; returned value from bits 0, then 1, etc.
;------------------------------------------------------------------------------



;------------------------------------------------------------------------------
; INCLUDES
;------------------------------------------------------------------------------

; Algorithm implementation include.

                .INCLUDE        "a2k6algo-rnd-s.inc"



;------------------------------------------------------------------------------
; UNINITIALISED DATA SEGMENT (BSS)
;------------------------------------------------------------------------------

                .BSS


; Current state of the shift register (hi and lo bytes).

rnd_sr_hi       .RES            1
rnd_sr_lo       .RES            1


; Number of bits to shift (rnd_shift_bits sub-routine input data).

rnd_shift       .RES            1


; Calculated feedback bit (low bit) (rnd_shift_bits sub-routine work data).

rnd_fback       .RES            1


; Last calculated random value (rnd_get_[bit|bits|byte] sub-routine out data).

rnd_value       .RES            1



;------------------------------------------------------------------------------
; MACROS
;------------------------------------------------------------------------------



;------------------------------------------------------------------------------
; FUNCTIONS
;------------------------------------------------------------------------------

                .CODE


;------------------------------------------------------------------------------
; Calculate the next bit by shifting the shift register 1-bit with feedback.
;
; Work: A = Undefined.
; Output: Carry (C) flag contains next bit of random data.
;------------------------------------------------------------------------------
rnd_next_bit:
                RND_NEXT_BIT
                RTS


;------------------------------------------------------------------------------
; Calculate the next number of bits given by rnd_shift value.
;
; Input: rnd_shift
; Work: A = Undefined, X = 0.
;------------------------------------------------------------------------------
rnd_next_bits:
                LDX             rnd_shift
                BEQ             @rnd_next_done
@rnd_next_again:
                JSR             rnd_next_bit
                DEX
                BNE             @rnd_next_again
@rnd_next_done:
                RTS


;------------------------------------------------------------------------------
; Get a single bit of random data and place it into rnd_value.
;
; Output: A = rnd_value = random bit (low bit).
;------------------------------------------------------------------------------
rnd_get_bit:
                JSR             rnd_next_bit
                LDA             #$00
                ROL             A
                STA             rnd_value
                RTS


;------------------------------------------------------------------------------
; Get (rnd_shift) number of bits (1-8) and place it into rnd_value.
;
; Input: rnd_shift the number of bits to include in the random value (1-8).
; Output: rnd_value = random value (lower bits random bit (0 | 1).
;
; Note: data is ordered from opposite to rnd_get_byte and value is in low bits.
;------------------------------------------------------------------------------
rnd_get_bits:
                RTS

;------------------------------------------------------------------------------
; Get a byte of bits and place it into rnd_value.
; Output: rnd_value = random bit (0 | 1).
;------------------------------------------------------------------------------
rnd_get_byte:
                LDA             rnd_sr_lo
                STA             rnd_value
                JSR             rnd_next_bit
                JSR             rnd_next_bit
                JSR             rnd_next_bit
                JSR             rnd_next_bit
                JSR             rnd_next_bit
                JSR             rnd_next_bit
                JSR             rnd_next_bit
                JSR             rnd_next_bit
                RTS



;------------------------------------------------------------------------------


