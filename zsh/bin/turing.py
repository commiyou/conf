#! /usr/bin/env python
# coding:gb18030
import sys
import itertools

sy_ovl_id = "12098-1"
dz_ovl_id = "12098-dz"
flow = "wise"
if flow == "wise":
    table = "basedata.fc_shitu_wise"
    cmatch_qry = "t1.cmatch in ('222', '223')"
else:
    table = "basedata.fc_shitu_pc"
    cmatch_qry = "t1.cmatch in ('204', '225')"

sy_mt_id_list = [9015, 9021, 9022, 9023]
sy_mt_id_list = [9022, 3136]
dz_mt_id_list = []
event_time_start = 20170529
event_time_end = 20170530

colums = []

sy_mt_sql = []
if sy_mt_id_list:
    sy_total_likes = []
    for mt in sy_mt_id_list:
        for term in ["shows", "click", "charge"]:
            sy_mt_sql.append('COALESCE(case when (t1.ovlexp_id_list like "%{0}%" and t1.mt_id like "%{1}%") then t1.{2} END, 0) as sy_{1}_mt_{2}'.format(sy_ovl_id, mt, term))
            colums.append('sy_{0}_mt_{1}'.format(mt, term))
        sy_total_likes.append('t1.mt_id like "%{0}%"'.format(mt))

    for term in ["shows", "click", "charge"]:
        sy_mt_sql.append('COALESCE(case when (t1.ovlexp_id_list like "%{0}%" and ({1})) then t1.{2} END, 0) as sy_total_mt_{2}'.format(sy_ovl_id, " or ".join(sy_total_likes), term))
        colums.append('sy_{0}_mt_{1}'.format("total", term))

dz_mt_sql = []
if dz_mt_id_list:
    dz_total_likes = []
    for mt in dz_mt_id_list:
        for term in ["shows", "click", "charge"]:
            dz_mt_sql.append('COALESCE(case when (t1.ovlexp_id_list like "%{0}%" and t1.mt_id like "%{1}%") then t1.{2} END, 0) as dz_{1}_mt_{2}'.format(dz_ovl_id, mt, term))
            colums.append('dz_{0}_mt_{1}'.format(mt, term))
        dz_total_likes.append('t1.mt_id like "%{0}%"'.format(mt))

    for term in ["shows", "click", "charge"]:
        dz_mt_sql.append('COALESCE(case when (t1.ovlexp_id_list like "%{0}%" and ({1})) then t1.{2} END, 0) as dz_total_mt_{2}'.format(dz_ovl_id, " or ".join(dz_total_likes), term))
        colums.append('dz_{0}_mt_{1}'.format("total", term))

sy_exp_sql = []
for term in ["shows", "click", "charge"]:
    sy_exp_sql.append('COALESCE(case when (t1.ovlexp_id_list like "%{0}%") then t1.{1} END, 0) as sy_exp_{1}'.format(sy_ovl_id, term))
    colums.append('sy_exp_{0}'.format(term))

dz_exp_sql = []
for term in ["shows", "click", "charge"]:
    dz_exp_sql.append('COALESCE(case when (t1.ovlexp_id_list like "%{0}%") then t1.{1} END, 0) as dz_exp_{1}'.format(dz_ovl_id, term))
    colums.append('dz_exp_{0}'.format(term))

qry_sqls = ',\n'.join(itertools.chain(sy_mt_sql, dz_mt_sql, sy_exp_sql, dz_exp_sql))


time_range = "t1.event_day >= {0} and t1.event_day <= {1}".format(event_time_start, event_time_end)
ovl_exp_qry = 't1.ovlexp_id_list like "%{0}%" or t1.ovlexp_id_list like "%{1}%"'.format(sy_ovl_id, dz_ovl_id)
colums_qry = ',\n'.join('sum({0}) as {0}'.format(x) for x in colums)
winfo_tpl = """
with winfo_data as (
select winfoid as key, absolute_rank,
{0}
from {1} t1
where ({2})
and ({3})
and ({4})
)
select key, absolute_rank,
{5}
from winfo_data
group by key,absolute_rank
""".format(qry_sqls, table, time_range, cmatch_qry, ovl_exp_qry, colums_qry)

print winfo_tpl
for mt in sy_mt_id_list:
    print "########################"
    mt_info = """
    with rank_dzx as (
    select absolute_rank,
    sum(sy_{0}_mt_shows) as mt_shows, sum(sy_{0}_mt_click) as mt_clicks, sum(sy_{0}_mt_charge) as mt_charges,
    sum(sy_exp_shows) as exp_shows, sum(sy_exp_click) as exp_clicks, sum(sy_exp_charge) as exp_charges,
    sum(dz_exp_shows) as dz_shows, sum(dz_exp_click) as dz_clicks, sum(dz_exp_charge) as dz_charges
    FROM temporary.job_b04b_7f75aa81ff76 t1
    group by absolute_rank)
    select absolute_rank,
    mt_shows, mt_clicks, mt_charges,
    exp_shows, exp_clicks, exp_charges,
    dz_shows, dz_clicks, dz_charges,
    mt_clicks/mt_shows as mt_ctr2,
    exp_clicks/exp_shows as exp_ctr2,
    dz_clicks/dz_shows as dz_ctr2,
    (mt_clicks/mt_shows - dz_clicks/dz_shows) / (dz_clicks/dz_shows) as mt_ctr2_inc,
    (exp_clicks/exp_shows - dz_clicks/dz_shows) / (dz_clicks/dz_shows) as exp_ctr2_inc,
    mt_charges/(10*mt_clicks) as mt_acp,
    exp_charges/(10*exp_clicks) as exp_acp,
    dz_charges/(10*dz_clicks) as dz_acp
    from rank_dzx""".format(mt)
    print mt_info
