-- database name : dishes_db

drop table if exists cartitems;

drop table if exists carts;

drop table if exists dishes;

drop table if exists orderitems;

drop table if exists orders;

drop table if exists review;

drop table if exists users;

/*==============================================================*/
/* Table: cartitems                                             */
/*==============================================================*/
create table cartitems
(
   ciid                 bigint not null auto_increment,
   cid                  bigint,
   did                  bigint,
   ciquantity           int not null,
   citotal              decimal(10,2),
   primary key (ciid)
);

/*==============================================================*/
/* Table: carts                                                 */
/*==============================================================*/
create table carts
(
   cid                  bigint not null auto_increment,
   uid                  bigint,
   ctotal               decimal(10,2),
   primary key (cid)
);

/*==============================================================*/
/* Table: dishes                                                */
/*==============================================================*/
create table dishes
(
   did                  bigint not null auto_increment,
   dname                varchar(30) not null,
   ddescription         text,
   dprice               decimal(10,2) not null,
   davailable           bool not null,
   primary key (did)
);

/*==============================================================*/
/* Table: orderitems                                            */
/*==============================================================*/
create table orderitems
(
   oiid                 bigint not null auto_increment,
   oid                  bigint,
   did                  bigint,
   oiquantity           int not null,
   oitotal              decimal(10,2),
   primary key (oiid)
);

/*==============================================================*/
/* Table: orders                                                */
/*==============================================================*/
create table orders
(
   oid                  bigint not null auto_increment,
   uid                  bigint,
   ostatus              enum('ONGOING','FINISHED','CANCELED') not null,
   ototal               decimal(10,2),
   oaddress             text not null,
   otime                timestamp not null,
   onote                text,
   primary key (oid)
);

/*==============================================================*/
/* Table: review                                                */
/*==============================================================*/
create table review
(
   rid                  bigint not null auto_increment,
   oid                  bigint,
   uid                  bigint,
   rscore               int not null,
   rtext                text not null,
   primary key (rid)
);

/*==============================================================*/
/* Table: users                                                 */
/*==============================================================*/
create table users
(
   uid                  bigint not null auto_increment,
   uname                varchar(30) not null,
   upassword            varchar(20) not null,
   uphone               varchar(11) not null,
   uaddress             text,
   urole                enum('ADMIN','CUS') not null,
   primary key (uid)
);

alter table cartitems add constraint FK_Relationship_2 foreign key (cid)
      references carts (cid) on delete cascade on update cascade;

alter table cartitems add constraint FK_Relationship_6 foreign key (did)
      references dishes (did) on delete cascade on update cascade;

alter table carts add constraint FK_Relationship_1 foreign key (uid)
      references users (uid) on delete cascade on update cascade;

alter table orderitems add constraint FK_Relationship_4 foreign key (oid)
      references orders (oid) on delete cascade on update cascade;

alter table orderitems add constraint FK_Relationship_5 foreign key (did)
      references dishes (did) on delete cascade on update cascade;

alter table orders add constraint FK_Relationship_3 foreign key (uid)
      references users (uid) on delete cascade on update cascade;

alter table review add constraint FK_Relationship_8 foreign key (oid)
      references orders (oid) on delete cascade on update cascade;

alter table review add constraint FK_Relationship_9 foreign key (uid)
      references users (uid) on delete cascade on update cascade;


DELIMITER $$
CREATE TRIGGER cartitems_before_insert
BEFORE INSERT ON cartitems
FOR EACH ROW
BEGIN
    SET NEW.citotal = (
        SELECT dprice FROM dishes WHERE did = NEW.did
    ) * NEW.ciquantity;
END
$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER cartitems_before_update
BEFORE UPDATE ON cartitems
FOR EACH ROW
BEGIN
    IF NEW.did <> OLD.did OR NEW.ciquantity <> OLD.ciquantity THEN
        SET NEW.citotal = (
            SELECT dprice FROM dishes WHERE did = NEW.did
        ) * NEW.ciquantity;
    END IF;
END
$$
DELIMITER ;

-- 插入后：重新计算购物车总金额 (ctotal)
DELIMITER $$
CREATE TRIGGER cartitems_after_insert
AFTER INSERT ON cartitems
FOR EACH ROW
BEGIN
    UPDATE carts SET ctotal = (
        SELECT COALESCE(SUM(citotal), 0) 
        FROM cartitems 
        WHERE cid = NEW.cid
    ) WHERE cid = NEW.cid;
END
$$
DELIMITER ;

-- 更新后：重新计算购物车总金额
DELIMITER $$
CREATE TRIGGER cartitems_after_update
AFTER UPDATE ON cartitems
FOR EACH ROW
BEGIN
    UPDATE carts SET ctotal = (
        SELECT COALESCE(SUM(citotal), 0) 
        FROM cartitems 
        WHERE cid = NEW.cid
    ) WHERE cid = NEW.cid;
END
$$
DELIMITER ;

-- 删除后：重新计算购物车总金额
DELIMITER $$
CREATE TRIGGER cartitems_after_delete
AFTER DELETE ON cartitems
FOR EACH ROW
BEGIN
    UPDATE carts SET ctotal = (
        SELECT COALESCE(SUM(citotal), 0) 
        FROM cartitems 
        WHERE cid = OLD.cid
    ) WHERE cid = OLD.cid;
END
$$
DELIMITER ;

-- 插入前：计算订单项总价 (oitotal)
DELIMITER $$
CREATE TRIGGER orderitems_before_insert
BEFORE INSERT ON orderitems
FOR EACH ROW
BEGIN
    SET NEW.oitotal = (
        SELECT dprice FROM dishes WHERE did = NEW.did
    ) * NEW.oiquantity;
END
$$
DELIMITER ;

-- 更新前：重新计算总价（当菜品ID或数量变化时）
DELIMITER $$
CREATE TRIGGER orderitems_before_update
BEFORE UPDATE ON orderitems
FOR EACH ROW
BEGIN
    IF NEW.did <> OLD.did OR NEW.oiquantity <> OLD.oiquantity THEN
        SET NEW.oitotal = (
            SELECT dprice FROM dishes WHERE did = NEW.did
        ) * NEW.oiquantity;
    END IF;
END
$$
DELIMITER ;

-- 插入后：重新计算订单总金额 (ototal)
DELIMITER $$
CREATE TRIGGER orderitems_after_insert
AFTER INSERT ON orderitems
FOR EACH ROW
BEGIN
    UPDATE orders SET ototal = (
        SELECT COALESCE(SUM(oitotal), 0) 
        FROM orderitems 
        WHERE oid = NEW.oid
    ) WHERE oid = NEW.oid;
END
$$
DELIMITER ;

-- 更新后：重新计算订单总金额
DELIMITER $$
CREATE TRIGGER orderitems_after_update
AFTER UPDATE ON orderitems
FOR EACH ROW
BEGIN
    UPDATE orders SET ototal = (
        SELECT COALESCE(SUM(oitotal), 0) 
        FROM orderitems 
        WHERE oid = NEW.oid
    ) WHERE oid = NEW.oid;
END
$$
DELIMITER ;

-- 删除后：重新计算订单总金额
DELIMITER $$
CREATE TRIGGER orderitems_after_delete
AFTER DELETE ON orderitems
FOR EACH ROW
BEGIN
    UPDATE orders SET ototal = (
        SELECT COALESCE(SUM(oitotal), 0) 
        FROM orderitems 
        WHERE oid = OLD.oid
    ) WHERE oid = OLD.oid;
END
$$
DELIMITER ;

-- 插入user后设置触发器插入cart
DELIMITER $$
CREATE TRIGGER after_user_insert
AFTER INSERT ON users
FOR EACH ROW
BEGIN
    INSERT INTO carts (uid, ctotal)
    VALUES (NEW.uid, 0.00); 
END
$$
DELIMITER ;