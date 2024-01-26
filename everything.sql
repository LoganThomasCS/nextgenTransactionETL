if object_id('tempdb..#everything') is not null drop table #everything;

create table #everything (
practice_id char(4),
practice_name varchar(100),
acct_id uniqueidentifier,
acct_nbr decimal(12,0),
guar_id uniqueidentifier,
guar_type char(1),
guar_name varchar(max),
person_id uniqueidentifier,
person_name varchar(max),
relationship_id varchar(30),
relationship_desc varchar(max),
enc_id  uniqueidentifier,
enc_status char(1),
enc_status_desc varchar(30),
enc_nbr decimal(11,0),
dos date,
pat_resp_date varchar(10),
location_id uniqueidentifier,
location_name varchar(200),
pat_type uniqueidentifier,
pat_type_desc varchar(100),
payer1_id uniqueidentifier,
payer1_name varchar(200),
payer1_fc_id uniqueidentifier,
payer1_fin_class varchar(200),
payer2_id uniqueidentifier,
payer2_name varchar(200),
payer2_fc_id uniqueidentifier,
payer2_fin_class varchar(200),
payer3_id uniqueidentifier,
payer3_name varchar(200),
payer3_fc_id uniqueidentifier,
payer3_fin_class varchar(200),
enc_tot_chg money,
enc_ins_bal money,
enc_bal money,
acct_tot_chg money,
acct_ins_bal money,
acct_bal money,
enc_pat_pmt money,
enc_ins_pmt money,
enc_pat_adj money,
enc_ins_adj money,
enc_pat_ref money,
enc_ins_ref money,
enc_ins_tot money,
enc_pat_tot money,
enc_pmt_tot money,
enc_ref_tot money,
enc_adj_tot money,
enc_ref_adj_amt money,
acct_pat_pmt money,
acct_ins_pmt money,
acct_pat_adj money,
acct_ins_adj money,
acct_pat_ref money,
acct_ins_ref money,
acct_ins_tot money,
acct_pat_tot money,
acct_pmt_tot money,
acct_ref_tot money,
acct_adj_tot money,
acct_ref_adj_amt money,
enc_ins_buc1 money,
enc_ins_buc2 money,
enc_ins_buc3 money,
enc_pat_buc money,
acct_ins_buc1 money,
acct_ins_buc2 money,
acct_ins_buc3 money,
acct_self_buc money,
enc_bad_debt_amt money,
acct_bad_debt_amt money
);



-- Gather GUIDs and other table specific information
insert into #everything(
		practice_id,
		enc_id) 
select distinct 
		practice_id,
		enc_id 
from patient_encounter w
where 1=1
	and guar_id in (select distinct guar_id from patient_encounter where practice_id = '0001' and enc_nbr in ('3169762','3251491','1333500','2809877','3169924'))

update e 
set 
		e.guar_id=pe.guar_id,
		e.guar_type=pe.guar_type,
		e.person_id=pe.person_id,
		e.enc_status=pe.enc_status,
		e.location_id=pe.location_id,
		e.enc_nbr=pe.enc_nbr,
		e.dos = convert(date,pe.enc_timestamp),
		e.pat_resp_date=pe.pat_resp_date,
		e.pat_type=pe.patient_type_id
from #everything e
	join patient_encounter pe on e.enc_id=pe.enc_id

update e
set 
		e.acct_id=a.acct_id,
		e.acct_nbr=a.acct_nbr
	
from #everything e 
	join accounts a on e.guar_id=a.guar_id

update e
set 
		e.payer1_id=ep1.payer_id,
		e.payer2_id=ep2.payer_id,
		e.payer3_id=ep3.payer_id
from #everything e
	left join encounter_payer ep1 on e.enc_id=ep1.enc_id and ep1.cob = 1
	left join encounter_payer ep2 on e.enc_id=ep2.enc_id and ep2.cob = 2
	left join encounter_payer ep3 on e.enc_id=ep3.enc_id and ep3.cob = 3

-- Gathering encounter level sums
update e
set e.enc_tot_chg = (select isnull(sum(c.amt),0) from charges c where e.enc_id=c.source_id and e.practice_id=c.practice_id)
from #everything e

update e
set e.enc_ins_buc1 = (select isnull(sum(c.cob1_amt),0) from charges c where e.enc_id = c.source_id and e.practice_id=c.practice_id)
from #everything e

update e
set e.enc_ins_buc2 = (select isnull(sum(c.cob2_amt),0)  from charges c where e.enc_id = c.source_id and e.practice_id=c.practice_id)
from #everything e

update e
set e.enc_ins_buc3 = (select isnull(sum(c.cob3_amt),0) from charges c where e.enc_id = c.source_id and e.practice_id=c.practice_id)
from #everything e

update e
set e.enc_pat_buc = (select isnull(sum(c.pat_amt),0) from charges c where e.enc_id = c.source_id and e.practice_id=c.practice_id)
from #everything e

update e
set e.enc_ins_pmt =  (select isnull(sum(td.paid_amt),0)
						from trans_detail td, transactions tr 
						where td.source_id=e.enc_id 
							and tr.trans_id=td.trans_id 
							and td.practice_id=tr.practice_id 
							and td.practice_id = e.practice_id 
							and tr.source = 'T')
from #everything e 


update e
set e.enc_ins_adj =  (select isnull(sum(td.adj_amt),0)
						from trans_detail td, transactions tr 
						where td.source_id=e.enc_id 
							and tr.trans_id=td.trans_id 
							and td.practice_id=tr.practice_id 
							and td.practice_id = e.practice_id 
							and td.post_ind = 'Y' 
							and tr.source = 'T' 
							and tr.type <> 'R')
from #everything e 

update e
set e.enc_ins_ref =  (select isnull(sum(td.adj_amt),0) 
						from trans_detail td, transactions tr 
						where td.source_id=e.enc_id 
							and tr.trans_id=td.trans_id 
							and td.practice_id=tr.practice_id 
							and td.practice_id = e.practice_id 
							and td.post_ind = 'Y'
							and tr.source = 'T' 
							and tr.type = 'R')
from #everything e 

update e
set e.enc_pat_pmt =  (select isnull(sum(td.paid_amt),0)
						from trans_detail td, transactions tr 
						where td.source_id=e.enc_id 
							and tr.trans_id=td.trans_id 
							and td.practice_id=tr.practice_id 
							and td.practice_id = e.practice_id 
							and tr.source = 'P')
from #everything e 


update e
set e.enc_pat_adj =  (select isnull(sum(td.adj_amt),0)
						from trans_detail td, transactions tr 
						where td.source_id=e.enc_id 
							and tr.trans_id=td.trans_id 
							and td.practice_id=tr.practice_id 
							and td.practice_id = e.practice_id 
							and td.post_ind = 'Y' 
							and tr.source = 'P' 
							and tr.type <> 'R')
from #everything e 

update e
set e.enc_pat_ref =  (select isnull(sum(td.adj_amt),0) 
						from trans_detail td, transactions tr 
						where td.source_id=e.enc_id 
							and tr.trans_id=td.trans_id 
							and td.practice_id=tr.practice_id 
							and td.practice_id = e.practice_id
							and td.post_ind = 'Y' 
							and tr.source = 'P' 
							and tr.type = 'R')
from #everything e 

-- Move bad debt amounts from patient bucket to bad debt amount
update e 
set 
	e.enc_bad_debt_amt = e.enc_pat_buc,
	e.enc_pat_buc = 0
from #everything e
where e.enc_status = 'A'

update e 
set 
	e.enc_bad_debt_amt = 0
from #everything e
where e.enc_status != 'A'

-- Encounter level final summing
update e
set 
		e.enc_pat_tot = e.enc_pat_pmt+e.enc_pat_adj+e.enc_pat_ref,
		e.enc_ins_tot = e.enc_ins_pmt+e.enc_ins_adj+e.enc_ins_ref,
		e.enc_ins_bal = e.enc_ins_buc1+e.enc_ins_buc2+e.enc_ins_buc3,
		e.enc_pmt_tot = e.enc_ins_pmt+e.enc_pat_pmt,
		e.enc_adj_tot = e.enc_ins_adj+e.enc_pat_adj,
		e.enc_ref_tot = e.enc_ins_ref+e.enc_pat_ref,
		e.enc_ref_adj_amt = (e.enc_ins_adj+e.enc_ins_ref)+(e.enc_pat_adj+e.enc_pat_ref),
		e.enc_bal = (e.enc_pat_pmt+e.enc_pat_adj+e.enc_pat_ref)+(e.enc_ins_pmt+e.enc_ins_adj+e.enc_ins_ref)+e.enc_tot_chg

	
from #everything e



-- Update Account level summing
update e 
set
	e.acct_tot_chg = (select isnull(sum(et.enc_tot_chg),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_ins_bal = (select isnull(sum(et.enc_ins_bal),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_bal = (select isnull(sum(et.enc_bal),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_pat_pmt = (select isnull(sum(et.enc_pat_pmt),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_ins_pmt = (select isnull(sum(et.enc_ins_pmt),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_pat_adj = (select isnull(sum(et.enc_pat_adj),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_ins_adj = (select isnull(sum(et.enc_ins_adj),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_pat_ref = (select isnull(sum(et.enc_pat_ref),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_ins_ref = (select isnull(sum(et.enc_ins_ref),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_pat_tot = (select isnull(sum(et.enc_pat_tot),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_ins_tot = (select isnull(sum(et.enc_ins_tot),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_pmt_tot = (select isnull(sum(et.enc_pmt_tot),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_adj_tot = (select isnull(sum(et.enc_adj_tot),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_ref_tot = (select isnull(sum(et.enc_ref_tot),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_ref_adj_amt = (select isnull(sum(et.enc_ref_adj_amt),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_ins_buc1 = (select isnull(sum(et.enc_ins_buc1),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_ins_buc2 = (select isnull(sum(et.enc_ins_buc2),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_ins_buc3 = (select isnull(sum(et.enc_ins_buc3),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_self_buc = (select isnull(sum(et.enc_pat_buc),0) from #everything et where et.guar_id=e.guar_id),
	e.acct_bad_debt_amt = (select isnull(sum(et.enc_bad_debt_amt),0) from #everything et where et.guar_id=e.guar_id)

from #everything e

-- Need relationship 

update e
set 
		e.relationship_id=pr.relation_code
from #everything e
	join person_relationship pr on e.guar_id=pr.person_id and e.person_id=pr.related_person_id 

update e
set e.practice_name=p.practice_name
from #everything e 
	join practice p on e.practice_id=p.practice_id

update e set e.guar_name = b.name
from #everything e
	join employer_mstr b on e.guar_id = b.employer_id and e.guar_type = 'E'

update e set e.guar_name = concat(isnull(b.last_name,''),', ',isnull(b.first_name,''))
from #everything e
	join person b on e.guar_id = b.person_id and e.guar_type = 'P'

update e set e.person_name = concat(isnull(b.last_name,''),', ',isnull(b.first_name,''))
from #everything e
	join person b on e.person_id = b.person_id 

update e set e.relationship_desc=c.description
from #everything e 
	join code_tables c on e.relationship_id=c.code and code_type = 'relation'

update e
set enc_status_desc= case when e.enc_status = 'H' then 'History' 
						when e.enc_status = 'B' then 'Billed'
						when e.enc_status = 'R' then 'Rebill'
						when e.enc_status = 'A' then 'Bad Debt'
							else 'Unbilled' 
								end
from #everything e 

update e set e.location_name=l.location_name
from #everything e
	join location_mstr l on e.location_id=l.location_id

update e set e.pat_type_desc=m.mstr_list_item_desc
from #everything e
	join mstr_lists m on e.pat_type=m.mstr_list_item_id and mstr_list_type like 'pat_type'

update e 
set 
		e.payer1_name=p1.payer_name,
		e.payer1_fc_id=p1.financial_class,
		e.payer2_name=p2.payer_name,
		e.payer2_fc_id=p2.financial_class,
		e.payer3_name=p3.payer_name,
		e.payer3_fc_id=p3.financial_class

from #everything e
	left join payer_mstr p1 on e.payer1_id=p1.payer_id
	left join payer_mstr p2 on e.payer2_id=p2.payer_id
	left join payer_mstr p3 on e.payer3_id=p3.payer_id

update e
set
		e.payer1_fin_class=m1.mstr_list_item_desc,
		e.payer2_fin_class=m2.mstr_list_item_desc,
		e.payer3_fin_class=m3.mstr_list_item_desc

from #everything e
	left join mstr_lists m1 on e.payer1_fc_id=m1.mstr_list_item_id and m1.mstr_list_type like 'fin_class'
	left join mstr_lists m2 on e.payer2_fc_id=m2.mstr_list_item_id and m2.mstr_list_type like 'fin_class'
	left join mstr_lists m3 on e.payer3_fc_id=m3.mstr_list_item_id and m3.mstr_list_type like 'fin_class'

