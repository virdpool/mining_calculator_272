cpu_model_str = """
AMD THREADRIPPER 3990X 48300 1
AMD THREADRIPPER 3970X 30500 1
AMD THREADRIPPER 3960X 28264 1
AMD THREADRIPPER 2990WX 20057 1
AMD THREADRIPPER 2950X 12000 1
AMD THREADRIPPER 2920X 10500 1
AMD THREADRIPPER 1950X 12550 1
AMD THREADRIPPER 1920X 10206 1
AMD THREADRIPPER 1900X 4841 1

AMD RYZEN 9 5950X 17124 1
AMD RYZEN 9 5900X 15500 1
*AMD RYZEN 9 3900 PRO 9680 1
AMD RYZEN 9 3950X 19827 1
AMD RYZEN 9 3900X 16301 1

AMD RYZEN 7 5800X 9555 1
AMD RYZEN 7 3800X 10420 1
AMD RYZEN 7 3700X 10321 1
AMD RYZEN 7 2700X 6550 1
AMD RYZEN 7 2700 5870 1
AMD RYZEN 7 1700X 5662 1

AMD RYZEN 5 5600X 7588 1
AMD RYZEN 5 3600X 8350 1
AMD RYZEN 5 3600 8277 1
AMD RYZEN 5 3500X 4900 1
AMD RYZEN 5 3500 4300 1
AMD RYZEN 5 2600X 4465 1
AMD RYZEN 5 2600 4300 1
AMD RYZEN 5 1600 4100 1
AMD RYZEN 5 1500X 3415 1

AMD RYZEN 3 3100 4600 1
AMD RYZEN 3 1300X 3010 1
AMD RYZEN 3 1200 2929 1

AMD EPYC 7742 44000 2
AMD EPYC 7702 43000 2
AMD EPYC 7R32 35155 2
AMD EPYC 7502P 25300 2
AMD EPYC 7402P 21000 2
AMD EPYC 7601 14900 2
AMD EPYC 7571 16600 2
AMD EPYC 7551P 15600 2
AMD EPYC 7401P 12432 2
AMD EPYC 7302P 13500 2
AMD EPYC 7351P 10101 2

INTEL XEON PLATINUM 8136 11250 8
INTEL XEON PLATINUM 8160 9500 8

INTEL XEON GOLD 6242 8909 4
INTEL XEON GOLD 6154 8400 4
INTEL XEON GOLD 6126 7230 4
INTEL XEON GOLD 6132 647 4
INTEL XEON GOLD 5122 2561 4

INTEL XEON SILVER 4216 8254 2
INTEL XEON SILVER 4214 6257 2

INTEL XEON BRONZE 3204 2040 2

INTEL XEON E5-2698 V4 6600 2
INTEL XEON E5-2687W V4 4582 2
INTEL XEON E5-2673 V4 8300 2
INTEL XEON E5-2673 V4 8300 2
*INTEL XEON E5-2643 V4 3157 2
INTEL XEON E5-2630 V4 4228 2
INTEL XEON E5-2609 V4 2200 2

INTEL XEON E5-4669 V3 6350 2
INTEL XEON E5-4627 V3 5000 4
INTEL XEON E5-2680 V3 5775 2
INTEL XEON E5-2699 V3 8148 2
INTEL XEON E5-2696 V3 7700 2
INTEL XEON E5-2678 V3 6400 2
INTEL XEON E5-2673 V3 5000 2
*INTEL XEON E5-2670 V3 4516 2
INTEL XEON E5-2667 V3 6950 2
INTEL XEON E5-2660 V3 4931 2
INTEL XEON E5-2630L V3 4007 2
INTEL XEON E5-2690 V3 5950 2
INTEL XEON E5-2683 V3 4337 2
INTEL XEON E5-2640 V3 3850 2
INTEL XEON E5-2630 V3 3777 2
INTEL XEON E5-2620 V3 3093 2

INTEL XEON E7-4880 V2 5500 4
INTEL XEON E5-2697 V2 4829 2
INTEL XEON E5-2696 V2 5100 2
INTEL XEON E5-2695 V2 4500 2
INTEL XEON E5-2687W V2 4293 2
INTEL XEON E5-2680 V2 3950 2
*INTEL XEON E5-2670 V2 2907 2
INTEL XEON E5 2650L V2 2848 2
INTEL XEON E5-2660 V2 3862 2
*INTEL XEON E5-2651 V2 2950 2
INTEL XEON E5-2650 V2 3400 2
*INTEL XEON E5-2637 V2 2235 2
INTEL XEON E5-2630 V2 2676 2
INTEL XEON E5-2630L V2 2478 2
INTEL XEON E5-2620 V2 2322 2
*INTEL XEON E5-2603 V2 700 2
INTEL XEON E5-1650 V2 2800 1
INTEL XEON E5-1607 V2 1890 1
*INTEL XEON E5-2403 V2 560 2

INTEL XEON E7-8837 2296 8
INTEL XEON E7-8870 2000 8
INTEL XEON E7-4870 3125 4

INTEL XEON E5-4640 2625 4
INTEL XEON E5-4617 2610 4
*INTEL XEON E5-2690 3200 2
INTEL XEON E5-2689 3552 2
INTEL XEON E5-2670 3200 2
INTEL XEON E5-2660 3080 2
INTEL XEON E5-2650 2717 2
INTEL XEON E5-2450L 2150 2
INTEL XEON E5-2640 2366 2
INTEL XEON E5-2620 1968 2
INTEL XEON E5-1620 2000 1

*INTEL XEON E5649 1368 2
*INTEL XEON E5645 1600 2
**INTEL XEON E5450 700 2
INTEL XEON E5620 1200 2

INTEL I9-10980XE 10201 1
*INTEL I9-9900K 6938 1

INTEL I7-11700K 5953 1
INTEL I7-10750H 2305 1
INTEL I7-10700K 5911 1
INTEL I7-10710U 3052 1

*INTEL I7-9700K 4960 1
INTEL I7-9750H 2920 1
INTEL I7-8809G 2374 1
INTEL I7-8700K 3556 1
INTEL I7-8700B 2700 1
INTEL I7-8559U 2396 1
INTEL I7-7700K 3210 1
INTEL I7-7700 2837 1
INTEL I7-6700K 2940 1
INTEL I7-6700 2585 1
INTEL I7-6850K 3500 1
INTEL I7-5960X 5240 1
INTEL I7-5820K 2980 1
INTEL I7-5775C 2399 1

INTEL I7-4960X 3850 1
INTEL I7-4930K 2990 1
INTEL I7-4790K 2800 1
INTEL I7-4790 2612 1
INTEL I7-4790 2734 1
INTEL I7-4770K 2700 1
INTEL I7-4770 2356 1
INTEL I7-4720HQ 5684 1
INTEL I7-3970X 2930 1
*INTEL I7-3930K 2400 1
INTEL I7-3770K 2710 1
INTEL I7-3770 2610 1
INTEL I7-2600 2224 1

*INTEL I5-9600K 3300 1
"""
###
HawxGT 17.06.2021 20:44 10980xe 8100
###

window.model_to_hashrate = {}
window.model_to_max_cpu = {}
window.cpu_model_list = cpu_model_str.replace(/\n+/g, "\n").trim().split("\n").map (t)->
  [model_part_list..., hashrate, max_cpu_per_motherboard] = t.split " "
  model = model_part_list.join " "
  hashrate = Math.round 0.7 * +hashrate
  model_to_hashrate[model] = hashrate
  model_to_max_cpu[model] = +max_cpu_per_motherboard
  {
    title : "(#{(hashrate/1000).toFixed(2).rjust 6, '\u00A0'} kh) #{model}"
    value : model
  }