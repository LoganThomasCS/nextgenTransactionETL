-- 3:34
if OBJECT_ID('tempdb..#chg') is not null drop table #chg; 
create table #chg (
practice_id char(4), 
guar_id uniqueidentifier,
guar_type char(1),
enc_id uniqueidentifier,
charge_id uniqueidentifier,
chgamt money,
chgcob1 money,
chgcob2 money,
chgcob3 money,
chgpat money, 
chginsbal money
);
insert into #chg (
		practice_id,
		enc_id,
		charge_id,
		chgamt,
		chgcob1,
		chgcob2,
		chgcob3,
		chgpat
)

select distinct
		c.practice_id,
		c.source_id,
		c.charge_id,
		sum(c.amt),
		sum(c.cob1_amt),
		sum(c.cob2_amt),
		sum(c.cob3_amt), 
		sum(c.pat_amt)
from  charges c 
	where c.practice_id in ('0001','0002','0003')--,'0012','0013','0015')
group by c.practice_id,
		 c.source_id,
		 c.charge_id

-- Calculate line item insurance balance 
update #chg set chginsbal = chgcob1+chgcob2+chgcob3


-- Sum transactions by charge
if object_id('tempdb..#trans') is not null drop table #trans;
select distinct
		c.practice_id,
		c.charge_id,
		(select sum(td.paid_amt) from trans_detail td, transactions tr where td.practice_id=c.practice_id and td.charge_id=c.charge_id and td.trans_id=tr.trans_id and td.post_ind = 'Y' and tr.source = 'P') chgpatpmt,
		(select sum(td.paid_amt) from trans_detail td, transactions tr where td.practice_id=c.practice_id and td.charge_id=c.charge_id and td.trans_id=tr.trans_id and td.post_ind = 'Y' and tr.source = 'T') chginspmt,
		(select sum(td.adj_amt) from trans_detail td, transactions tr where td.practice_id=c.practice_id and td.charge_id=c.charge_id and td.trans_id=tr.trans_id and td.post_ind = 'Y' and tr.source = 'P' and tr.type != 'R') chgpatadj,
		(select sum(td.adj_amt) from trans_detail td, transactions tr where td.practice_id=c.practice_id and td.charge_id=c.charge_id and td.trans_id=tr.trans_id and td.post_ind = 'Y' and tr.source = 'T' and tr.type != 'R') chginsadj,
		(select sum(td.adj_amt) from trans_detail td, transactions tr where td.practice_id=c.practice_id and td.charge_id=c.charge_id and td.trans_id=tr.trans_id and td.post_ind = 'Y' and tr.source = 'P' and tr.type = 'R') chgpatref,
		(select sum(td.adj_amt) from trans_detail td, transactions tr where td.practice_id=c.practice_id and td.charge_id=c.charge_id and td.trans_id=tr.trans_id and td.post_ind = 'Y' and tr.source = 'T' and tr.type = 'R') chginsref,
		0 encbal
	into #trans
from #chg c
group by c.practice_id,
		 c.charge_id


update #trans set chgpatpmt = 0 where chgpatpmt is null
update #trans set chginspmt = 0 where chginspmt is null
update #trans set chgpatadj = 0 where chgpatadj is null
update #trans set chginsadj = 0 where chginsadj is null
update #trans set chgpatref = 0 where chgpatref is null
update #trans set chginsref = 0 where chginsref is null

update c 
set c.guar_id = e.guar_id,
	c.guar_type=e.guar_type
from #chg c
	join patient_encounter e on c.enc_id=e.enc_id

delete from #chg where guar_id is null

-- TODO: Add final linked server table insert

select distinct top 100
		c.*,
		t.chginspmt,
		t.chgpatpmt,
		t.chginsadj,
		t.chgpatadj,
		t.chginsref,
		t.chgpatref,
		c.chgamt+(t.chginspmt+t.chgpatpmt+t.chginsadj+t.chgpatadj+t.chginsref+t.chgpatref) chgencbal 
	into #tempynums
from #chg c 
	join #trans t on c.practice_id=t.practice_id
					and c.charge_id=t.charge_id


--SELECT * 
--FROM tempdb.sys.columns
--WHERE object_id = OBJECT_ID('tempdb..#tempynums');
