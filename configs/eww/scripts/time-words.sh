#!/bin/bash
# "Time is Nine.Thirty One" style
hour=$(date +%-I)
min=$(date +%-M)

words=( "" One Two Three Four Five Six Seven Eight Nine Ten Eleven Twelve )
ones=( "" One Two Three Four Five Six Seven Eight Nine )
tens=( "" Ten Twenty Thirty Forty Fifty Sixty )

hw=${words[$hour]}
if (( min == 0 )); then
  echo "Time is ${hw}.O'Clock"
elif (( min < 10 )); then
  echo "Time is ${hw}.O'Clock"  # or Zero ${ones[$min]}
  echo "Time is ${hw}.${ones[$min]}"
elif (( min < 20 )); then
  teens=( Ten Eleven Twelve Thirteen Fourteen Fifteen Sixteen Seventeen Eighteen Nineteen )
  echo "Time is ${hw}.${teens[$((min-10))]}"
else
  t=$((min/10)) o=$((min%10))
  if (( o == 0 )); then echo "Time is ${hw}.${tens[$t]}"
  else echo "Time is ${hw}.${tens[$t]} ${ones[$o]}"
  fi
fi
