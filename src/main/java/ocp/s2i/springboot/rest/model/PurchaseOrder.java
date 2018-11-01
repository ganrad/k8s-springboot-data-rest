/*
 * Copyright 2005-2016 Red Hat, Inc.
 *
 * Red Hat licenses this file to you under the Apache License, version
 * 2.0 (the "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 * implied.  See the License for the specific language governing
 * permissions and limitations under the License.
 */
package ocp.s2i.springboot.rest.model;

import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;

@Entity
public class PurchaseOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long id;
    private String item;
    private Float price;
    private Integer quantity;
    private String description;
    private String cname; // Customer name
    private String dcode; // Discount code
    private String origin;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
	this.id = id;
    }

    public String getItem() {
        return item;
    }

    public void setItem(String item) {
        this.item = item;
    }

    public Float getPrice() {
        return price;
    }

    public void setPrice(Float price) {
        this.price = price;
    }

    public Integer getQuantity() {
        return quantity;
    }
    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getCname() {
        return cname;
    }

    public void setCname(String cname) {
        this.cname = cname;
    }

    public String getDcode() {
        return dcode;
    }

    public void setDcode(String dcode) {
        this.dcode = dcode;
    }

    public String getOrigin() {
        return origin;
    }

    public void setOrigin(String origin) {
        this.origin = origin;
    }

// Uncomment this method for retrieving order total !!

    public Float getDiscountAmount() {
	return ( (this.price * this.quantity) * ( Float.parseFloat(this.dcode) / 100 ) );
    } 

    public Float getOrderTotal() {
	return ( (this.price * this.quantity) - getDiscountAmount() );
    }


    public String toString() {
	StringBuffer sb = new StringBuffer();
	sb.append(
	  "ID=" + getId() + ", " +
          "Item=" + getItem() + ", " +
          "Customer=" + getCname() + ", " +
	  "Quantity=" + getQuantity() + ", " +
	  "Origin=" + getOrigin());
	return(sb.toString());
    }
}
