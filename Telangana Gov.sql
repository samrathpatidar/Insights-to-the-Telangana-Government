-- Data Cleaning

ALTER TABLE fact_stamps
MODIFY month date;


/* 	Primary Questions:
Stamp Registration
1. How does the revenue generated from document registration vary across districts in Telangana?
*/

select
dd.district,
sum(documents_registered_rev) as tot_rev
from fact_stamps as fs
join dim_districts dd on dd.dist_code = fs.dist_code
GROUP BY dd.district
;
        
        
-- 1. (b)List down the top 5 districts that showed the highest document registration revenue growth between FY 2019 and 2022.

with cte as (
select
	dist_code,
    year(month) as year,
    sum(documents_registered_rev) as sum_rev,
	lead(sum(documents_registered_rev),3) over(partition by dist_code order by year(month)) as fut_rev
from fact_stamps
GROUP BY dist_code, year(month)
)
select
dd.district,
(fut_rev-sum_rev)*100/sum_rev as '%_growth_19_to_22'
from cte
join dim_districts dd on dd.dist_code = cte.dist_code
where year = 2019
order by 2 desc
limit 5;


-- 2. (a) How does the revenue generated from document registration compare to the revenue generated from e-stamp challans across districts?

select
dd.district,
sum(documents_registered_rev) as doc_tot_rev,
sum(estamps_challans_rev) as stmp_tot_rev
from fact_stamps as fs
join dim_districts dd on dd.dist_code = fs.dist_code
GROUP BY dd.district;   


-- 2. (b) List down the top 5 districts where e-stamps revenue contributes significantly more to the revenue than the documents in FY 2022?

select
dd.district,
sum(documents_registered_rev) as doc_tot_rev,
sum(estamps_challans_rev) as stmp_tot_rev,
sum(estamps_challans_rev) - sum(documents_registered_rev) as stmp_doc_rev 
from fact_stamps as fs
join dim_districts dd on dd.dist_code = fs.dist_code
where year(fs.month) = 2022
GROUP BY dd.district, year(fs.month)
order by stmp_doc_rev desc
limit 5
;


-- 3. (a) Is there any alteration of e-Stamp challan count and document registration count pattern since the implementation of e-Stamp challan?
-- If so, what suggestions would you propose to the government?

select year(month),
sum(documents_registered_cnt) as doc_tot,
sum(estamps_challans_cnt) as stmp_tot
from fact_stamps
GROUP BY year(month);
/* There is continous increase in e-Stamp challan count and document registration count is in decreasing trend since the implementation of e-Stamp challan.
e-Stamp challan is a way of paying non-judicial stamp duty electronically through the MCA21 system. Document registration is the process of recording a document with a recognized officer and to safeguard its original copies.
Registration of every document is not necessary but doing so affirms the authenticity and helps in avoiding legal process.
As we observed that there is a continuous increase in e-Stamp challan count and a decreasing trend in document registration count since the implementation of e-Stamp challan.
This may indicate that some people are opting for e-Stamp challan as a convenient and secure way of paying stamp duty, but are not registering their documents with the authorities.
This may lead to some legal issues or disputes in the future, as unregistered documents may not be valid or enforceable in court.
Some possible suggestions to the government to address this issue are:
1. To create more awareness and education among the public about the benefits and importance of document registration, such as ensuring legal validity, preventing fraud, protecting rights and interests, etc.
2. To provide incentives or discounts for document registration, such as reducing the registration fees, offering tax benefits, simplifying the procedures, etc.
3. To enforce stricter penalties or sanctions for non-registration of documents, such as imposing fines, canceling transactions, revoking licenses, etc.
4. To integrate the e-Stamp challan system with the document registration system, such that the payment of stamp duty is automatically linked to the registration of documents, and vice versa.
I hope this answer was helpful and informative.
*/


-- 4. Categorize districts into three segments based on their stamp registration revenue generation during the fiscal year 2021 to 2022.

select district,
sum(documents_registered_rev) + sum(estamps_challans_rev) as tot_rev,
ntile(3) over(order by (sum(documents_registered_rev) + sum(estamps_challans_rev)) desc) as category
from fact_stamps fs
join dim_districts dd on dd.dist_code = fs.dist_code
where year(month) in (2021, 2022)
group by district;


-- Transportation
-- 	5. 	Investigate whether there is any correlation between vehicle sales and specific months or seasons in different districts.
-- 		Are there any months or seasons that consistently show higher or lower sales rate, and if yes, what could be the driving factors?
-- 		(Consider Fuel-Type category only)

with cte as
(
select 
dist_code, monthname(month),
sum(fuel_type_petrol)+ sum(fuel_type_diesel)+sum(fuel_type_electric)+sum(fuel_type_others) as veh_sale,
rank() over(PARTITION BY dist_code order by sum(fuel_type_petrol)+ sum(fuel_type_diesel)+sum(fuel_type_electric)+sum(fuel_type_others)) as rnk
 from fact_transport
 GROUP BY dist_code, monthname(month)
)
select *
from cte
where rnk > 8 or rnk < 4
order by rnk
;
 
 -- As it is observed that mostly sale is high in the month of April, May, Sept and Dec and
 -- low in month of March, June, July, October, November.
 
 /*
The posible driving factors can:
1. **Agricultural Seasons:** Telangana has an agrarian economy, and agricultural cycles can influence purchasing patterns. For instance, the months of April and May might coincide with post-harvest periods
	when farmers have additional income to spend on vehicles. June and July could align with sowing and pre-harvest seasons when farmers might have less disposable income.
2. **Festivals:** The state of Telangana celebrates festivals like Bathukamma and Dasara, which fall around September. During these festivals, people might purchases more vehicle.
3. **Weather Conditions:** Telangana experiences hot summers, and people might prefer purchasing vehicles with air conditioning during the warmer months, which could influence the higher sales in April and May.
 */
 
 
 -- 6. How does the distribution of vehicles vary by vehicle class (MotorCycle, MotorCar, AutoRickshaw, Agriculture) across different districts?
 -- 	Are there any districts with a predominant preference for a specific vehicle class? Consider FY 2022 for analysis.
 
 with cte as
 (select district,
	sum(vehicleClass_MotorCycle) as mcy,
	sum(vehicleClass_MotorCar) as mcr,
    sum(vehicleClass_AutoRickshaw) as ar,
    sum(vehicleClass_Agriculture) as agr
 from fact_transport ft
 join dim_districts dd on dd.dist_code = ft.dist_code
 where year(month) = 2022
 GROUP BY district)
 select district,
	round(mcy*100/(mcy+mcr+ar+agr),0) as 'MotorCycle_%',
    round(mcr*100/(mcy+mcr+ar+agr),0) as 'MotorCar_%',
    round(ar*100/(mcy+mcr+ar+agr),0) as 'AutoRickshaw_%',
    round(agr*100/(mcy+mcr+ar+agr),0) as 'Agriculture_%'
from cte
 ;
 
 -- Mostly all districts have MotorCycle as there predominant preference followed by MotorCar, Agriculture and AutoRickshaw but in Jayashankar Bhupalpally district
 -- Agriculture vehicle is sold more than MotorCar which shows that there is more agricultural activity in Jayashankar Bhupalpally district.
 
 
 -- 7. List down the top 3 and bottom 3 districts that have shown the highest and lowest vehicle sales growth during FY 2022 compared to FY 2021?
 --  	(Consider and compare categories: Petrol, Diesel and Electric)
 
 with cte as (
 select district, year(month) as yr,
	sum(fuel_type_petrol+fuel_type_diesel+fuel_type_electric) as tot_veh_sale,
    lag(sum(fuel_type_petrol+fuel_type_diesel+fuel_type_electric)) over(partition by district order by year(month)) as lg
 from fact_transport ft
 join dim_districts dd on dd.dist_code = ft.dist_code
 where year(month) in (2021, 2022)
 GROUP BY district, year(month)
 ),
top_3 as (select district, round((tot_veh_sale-lg)*100/lg,0) as '%_growth_in_2022', 'Top 3' as position from cte where yr = 2022 order by 2 desc limit 3),
bottom_3 as (select district, round((tot_veh_sale-lg)*100/lg,0) as '%_growth_in_2022', 'Bottom 3' as position from cte where yr = 2022 order by 2  limit 3)
select * from top_3 UNION select * from bottom_3
;


-- Ts-Ipass (Telangana State Industrial Project Approval and Self Certification System)
-- 8. List down the top 5 sectors that have witnessed the most significant investments in FY 2022.

select sector, round(sum(investment_in_cr),1)
from fact_TS_iPASS
where year(month) = 2022
group by sector
order by 2 desc
limit 5;


-- 9. List down the top 3 districts that have attracted the most significant sector investments
--    during FY 2019 to 2022? What factors could have led to the substantial investments in these particular districts?

select district, round(sum(investment_in_cr),1) as inv
from fact_ts_ipass ftp
 join dim_districts dd on dd.dist_code = ftp.dist_code
where year(month) in (2019, 2020, 2021, 2022)
GROUP BY district
order by inv desc
limit 3;


-- 10. Is there any relationship between district investments, vehicles
-- sales and stamps revenue within the same district between FY 2021 and 2022?

select
	district,
    year(ftp.month),
    round(sum(investment_in_cr),1),
    sum(fuel_type_diesel+fuel_type_petrol+fuel_type_electric+fuel_type_others),
    sum(documents_registered_rev+estamps_challans_rev)
from dim_districts dd
join fact_stamps fs on fs.dist_code = dd.dist_code
join fact_transport ft on ft.dist_code = dd.dist_code
join fact_ts_ipass ftp on ftp.dist_code = dd.dist_code
where year(ftp.month) in (2021, 2022)
GROUP BY district, year(ftp.month)
order by district;


-- 11. Are there any particular sectors that have shown substantial
--     investment in multiple districts between FY 2021 and 2022?

select sector, district, round(sum(investment_in_cr),1) as inv
from fact_ts_ipass ftp
 join dim_districts dd on dd.dist_code = ftp.dist_code
where year(month) in (2021, 2022)
GROUP BY sector, district
order by inv desc
;

-- Pharmaceuticals and Chemicals


-- 12. Can we identify any seasonal patterns or cyclicality in the
-- 		investment trends for specific sectors? Do certain sectors
-- 		experience higher investments during particular months?

select sector, month(month), round(sum(investment_in_cr),1) as inv
from fact_ts_ipass ftp
 join dim_districts dd on dd.dist_code = ftp.dist_code
GROUP BY month(month), sector
order by sector, month(month);

