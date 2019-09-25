---
--- RECREATE missing facility type approved products
---

INSERT INTO referencedata.facility_type_approved_products(id, versionnumber, orderableid, programid, facilitytypeid, maxperiodsofstock, minperiodsofstock, emergencyorderpoint, active, lastupdated)
  SELECT DISTINCT ON (rli.orderableId, r.programId, f.typeId)
  uuid_generate_v4(), 1, rli.orderableId, r.programId, f.typeId, COALESCE(rli.maxperiodsofstock, 0), 0, 0, FALSE, NOW()
  FROM
  requisition.requisition_line_items AS rli
    INNER JOIN requisition.requisitions AS r ON rli.requisitionId = r.id
    INNER JOIN referencedata.facilities AS f ON f.id = r.facilityId
    LEFT JOIN referencedata.facility_type_approved_products AS ftap ON f.typeId = ftap.facilitytypeid AND r.programId = ftap.programid AND rli.orderableid = ftap.orderableid
  WHERE
  ftap IS NULL;

---
--- UPDATE requisition.requisition_line_items
---

-- creates new table based on existing data
CREATE TABLE requisition.requisition_line_items_new AS
  SELECT rli.id, rli.adjustedconsumption, rli.approvedquantity, rli.averageconsumption, rli.beginningbalance,
         rli.calculatedorderquantity, COALESCE(rli.maxperiodsofstock, 0) as maxperiodsofstock, rli.maximumstockquantity, rli.nonfullsupply,
         rli.numberofnewpatientsadded, rli.orderableid, rli.packstoship, rli.priceperpack, rli.remarks,
         rli.requestedquantity, rli.requestedquantityexplanation, rli.skipped, rli.stockonhand, rli.total,
         rli.totalconsumedquantity, rli.totalcost, rli.totallossesandadjustments, rli.totalreceivedquantity,
         rli.totalstockoutdays, rli.requisitionid, rli.idealstockamount, rli.calculatedorderquantityisa,
         rli.additionalquantityrequired, o.versionNumber AS orderableversionnumber,
         ftap.id AS facilitytypeapprovedproductid, 1 as facilitytypeapprovedproductversionnumber
  FROM requisition.requisition_line_items AS rli
    INNER JOIN requisition.requisitions AS r ON rli.requisitionid = r.id
    INNER JOIN (SELECT id, MAX(versionNumber) as versionNumber FROM referencedata.orderables GROUP BY id) AS o ON rli.orderableId = o.id
    INNER JOIN referencedata.facilities AS f ON f.id = r.facilityId
    INNER JOIN referencedata.facility_types AS ft ON f.typeId = ft.id
    INNER JOIN referencedata.programs AS p ON r.programId = p.id
    INNER JOIN referencedata.facility_type_approved_products AS ftap ON ft.id = ftap.facilitytypeid AND p.id = ftap.programid AND rli.orderableid = ftap.orderableid;

-- removes dependencies
ALTER TABLE requisition.previous_adjusted_consumptions
DROP CONSTRAINT fk_ofrpexcgp8i7ppwit5kbs0ryr;
ALTER TABLE requisition.stock_adjustments
DROP CONSTRAINT fk_9nqi8imo7ty6jafeijhviynrt;

-- drops old version of the table
DROP TABLE requisition.requisition_line_items;

-- recreates constraints
ALTER TABLE requisition.requisition_line_items_new
ADD CONSTRAINT requisition_line_items_pkey PRIMARY KEY (id),
ADD CONSTRAINT fk_4sg1naierwgt9avsjcm76a2yl FOREIGN KEY (requisitionid)
REFERENCES requisition.requisitions (id) MATCH SIMPLE
  ON UPDATE NO ACTION ON DELETE NO ACTION;

-- renames the new table
ALTER TABLE requisition.requisition_line_items_new RENAME TO requisition_line_items;

-- restores dependencies
ALTER TABLE requisition.previous_adjusted_consumptions
ADD CONSTRAINT fk_ofrpexcgp8i7ppwit5kbs0ryr FOREIGN KEY (requisitionlineitemid)
REFERENCES requisition.requisition_line_items (id) MATCH SIMPLE
  ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE requisition.stock_adjustments
ADD CONSTRAINT fk_9nqi8imo7ty6jafeijhviynrt FOREIGN KEY (requisitionlineitemid)
REFERENCES requisition.requisition_line_items (id) MATCH SIMPLE
  ON UPDATE NO ACTION ON DELETE NO ACTION;

---
--- UPDATE requisition.available_products
---

-- creates new table based on existing data
CREATE TABLE requisition.available_products_new AS
  SELECT ap.requisitionid,
         ap.orderableid, o.versionNumber AS orderableversionnumber,
         ftap.id AS facilitytypeapprovedproductid, 1 AS facilitytypeapprovedproductversionnumber
  FROM requisition.available_products AS ap
    INNER JOIN requisition.requisitions AS r ON ap.requisitionid = r.id
    INNER JOIN (SELECT id, MAX(versionNumber) as versionNumber FROM referencedata.orderables GROUP BY id) AS o ON ap.orderableId = o.id
    INNER JOIN referencedata.facilities AS f ON f.id = r.facilityId
    INNER JOIN referencedata.facility_types AS ft ON f.typeId = ft.id
    INNER JOIN referencedata.programs AS p ON r.programId = p.id
    INNER JOIN referencedata.facility_type_approved_products AS ftap ON ft.id = ftap.facilitytypeid AND p.id = ftap.programid AND ap.orderableid = ftap.orderableid;

-- removes dependencies

-- drops old version of the table
DROP TABLE requisition.available_products;

-- recreates constraints
ALTER TABLE requisition.available_products_new
ADD CONSTRAINT fk_b8078votirpsmh2cpuvm0oull FOREIGN KEY (requisitionid)
REFERENCES requisition.requisitions (id) MATCH SIMPLE
  ON UPDATE NO ACTION ON DELETE NO ACTION;

-- renames the new table
ALTER TABLE requisition.available_products_new RENAME TO available_products;

-- restores dependencies

---
--- UPDATE fulfillment.order_line_items
---

-- creates new table based on existing data
CREATE TABLE fulfillment.order_line_items_new AS
  SELECT oli.id, oli.orderid, oli.orderableid, oli.orderedquantity, o.versionNumber AS orderableversionnumber
  FROM fulfillment.order_line_items AS oli
    INNER JOIN (SELECT id, MAX(versionNumber) as versionNumber FROM referencedata.orderables GROUP BY id) AS o ON oli.orderableId = o.id;

-- removes dependencies

-- drops old version of the table
DROP TABLE fulfillment.order_line_items;

-- recreates constraints
ALTER TABLE fulfillment.order_line_items_new
ADD CONSTRAINT order_line_items_pkey PRIMARY KEY (id),
ADD CONSTRAINT order_line_items_orderid_fk FOREIGN KEY (orderid)
REFERENCES fulfillment.orders (id) MATCH SIMPLE
  ON UPDATE NO ACTION ON DELETE NO ACTION;

-- renames the new table
ALTER TABLE fulfillment.order_line_items_new RENAME TO order_line_items;

-- restores dependencies

---
--- UPDATE fulfillment.shipment_line_items
---

-- creates new table based on existing data
CREATE TABLE fulfillment.shipment_line_items_new AS
  SELECT sli.id, sli.lotid, sli.orderableid, sli.quantityshipped, sli.shipmentid, sli.extradata, o.versionNumber AS orderableversionnumber
  FROM fulfillment.shipment_line_items AS sli
    INNER JOIN (SELECT id, MAX(versionNumber) as versionNumber FROM referencedata.orderables GROUP BY id) AS o ON sli.orderableId = o.id;

-- removes dependencies

-- drops old version of the table
DROP TABLE fulfillment.shipment_line_items;

-- recreates constraints
ALTER TABLE fulfillment.shipment_line_items_new
ADD CONSTRAINT shipment_line_items_pkey PRIMARY KEY (id),
ADD CONSTRAINT shipment_line_items_shipmentid_fk FOREIGN KEY (shipmentid)
REFERENCES fulfillment.shipments (id) MATCH SIMPLE
  ON UPDATE NO ACTION ON DELETE NO ACTION;

-- renames the new table
ALTER TABLE fulfillment.shipment_line_items_new RENAME TO shipment_line_items;

-- restores dependencies

---
--- UPDATE fulfillment.proof_of_delivery_line_items
---

-- creates new table based on existing data
CREATE TABLE fulfillment.proof_of_delivery_line_items_new AS
  SELECT podli.id, podli.proofofdeliveryid, podli.notes, podli.quantityaccepted, podli.quantityrejected, podli.orderableid,
         podli.lotid, podli.vvmstatus, podli.usevvm, podli.rejectionreasonid, o.versionNumber AS orderableversionnumber
  FROM fulfillment.proof_of_delivery_line_items AS podli
    INNER JOIN (SELECT id, MAX(versionNumber) as versionNumber FROM referencedata.orderables GROUP BY id) AS o ON podli.orderableId = o.id;

-- removes dependencies

-- drops old version of the table
DROP TABLE fulfillment.proof_of_delivery_line_items;

-- recreates constraints
ALTER TABLE fulfillment.proof_of_delivery_line_items_new
ADD CONSTRAINT proof_of_delivery_line_items_pkey PRIMARY KEY (id),
ADD CONSTRAINT proof_of_delivery_line_items_proofofdeliveryid_fk FOREIGN KEY (proofofdeliveryid)
REFERENCES fulfillment.proofs_of_delivery (id) MATCH SIMPLE
  ON UPDATE NO ACTION ON DELETE NO ACTION;

-- rename the new table
ALTER TABLE fulfillment.proof_of_delivery_line_items_new RENAME TO proof_of_delivery_line_items;

-- restores dependencies
