#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

magick -size 1024x1024 xc:white -fill none -stroke '#1f2937' -strokewidth 34 \
  -draw "line 216,500 512,246 line 512,246 808,500 rectangle 292,458 732,810 rectangle 438,630 586,810 rectangle 342,560 454,670 rectangle 586,560 698,670 line 696,342 696,250 line 696,250 784,250 line 784,250 784,418" \
  assets/targets/easy/house_001.png

magick -size 1024x1024 xc:white -fill none -stroke '#1f2937' -strokewidth 34 \
  -draw "polygon 512,162 656,530 494,692 332,530 circle 512,384 574,384 polygon 360,558 238,680 388,698 polygon 664,558 786,680 636,698 line 454,720 426,862 line 426,862 512,784 line 512,784 598,862 line 598,862 570,720 line 432,604 592,604" \
  assets/targets/easy/rocket_001.png

magick -size 1024x1024 xc:white -fill none -stroke '#1f2937' -strokewidth 34 \
  -draw "polygon 306,374 236,224 404,312 polygon 718,374 788,224 620,312 ellipse 512,470 230,264 0,360 circle 420,456 422,456 circle 604,456 606,456 line 512,520 512,596 arc 442,578 582,674 20,160 line 352,544 202,544 line 362,606 222,606 line 672,544 822,544 line 662,606 802,606" \
  assets/targets/easy/cat_001.png

magick -size 1024x1024 xc:white -fill none -stroke '#1f2937' -strokewidth 34 \
  -draw "line 512,166 512,262 circle 512,132 546,132 roundrectangle 272,262 752,692 72,72 circle 420,426 468,426 circle 604,426 652,426 line 416,570 608,570 rectangle 138,402 212,580 rectangle 812,402 886,580 line 378,692 378,820 line 646,692 646,820 line 324,820 432,820 line 592,820 700,820" \
  assets/targets/medium/robot_001.png

supabase --experimental --yes storage rm ss:///targets/easy/house_001.png || true
supabase --experimental --yes storage rm ss:///targets/easy/rocket_001.png || true
supabase --experimental --yes storage rm ss:///targets/easy/cat_001.png || true
supabase --experimental --yes storage rm ss:///targets/medium/robot_001.png || true
supabase --experimental --yes storage rm ss:///targets/coop/easy/house_duo_001.png || true

supabase --experimental storage cp assets/targets/easy/house_001.png ss:///targets/easy/house_001.png --content-type image/png
supabase --experimental storage cp assets/targets/easy/rocket_001.png ss:///targets/easy/rocket_001.png --content-type image/png
supabase --experimental storage cp assets/targets/easy/cat_001.png ss:///targets/easy/cat_001.png --content-type image/png
supabase --experimental storage cp assets/targets/medium/robot_001.png ss:///targets/medium/robot_001.png --content-type image/png
supabase --experimental storage cp assets/targets/coop/easy/house_duo_001.png ss:///targets/coop/easy/house_duo_001.png --content-type image/png
