/*
 * Fenix Open Source accounting system
 * Item managment
 *	
 * Copyright 2015 Davor Siklic (www.msoft.cz)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.txt.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site https://www.gnu.org/).
 *
 */

#include "marinas-gui.ch"
#include "fenix.ch"
#include "hbthread.ch"

memvar cRPath, cPath, hIni

procedure browse_items()

local cWin := "item_win"
local cAll, lTax := TaxStatus()

if !OpenItems(, 2, .T.)
	return
endif

cAll := alias()

//&(cAll) -> (dbgotop()) 
CREATE WINDOW (cWin)
	row 0
	col 0
	width 1050
	height 600
	CAPTION _I("Browse items")
	CHILD .T.
	MODAL .T.
	//TOPMOST .t.
	FONTSIZE 16
	create Browse item_b
		row 10
		col 10
		width 800
		height 564 		
		if lTax
			COLUMNFIELDALL { cAll+"->name", cAll+"->unit", cAll+"->type", cAll+"->price", cAll+"->tax" }
			COLUMNHEADERALL { _I("Name"), _I("Unit") , _I("Type"), _I("Price"), _I("Tax") }
			COLUMNWIDTHALL { 460, 80, 85, 122, 50 }
			COLUMNALIGNALL { Qt_AlignLeft, Qt_AlignLeft, Qt_AlignLeft, Qt_AlignRight, Qt_AlignRight }
		else
			COLUMNFIELDALL { cAll+"->name", cAll+"->unit", cAll+"->type", cAll+"->price" }
			COLUMNHEADERALL { _I("Name"), _I("Unit") , _I("Type"), _I("Price") }
			COLUMNWIDTHALL { 350, 80, 80, 122 }
			COLUMNALIGNALL { Qt_AlignCenter, Qt_AlignLeft, Qt_AlignLeft, Qt_AlignRight }
		endif
		workarea cAll
		value 1
		//AUTOSIZE .t.
		rowheightall 24
		FONTSIZE 16
		//ONENTER print_invoice(mg_get(cWin, "invoice_b", "cell", mg_get(cWin,"invoice_b","value"), 1))
		//ONDBLCLICK print_invoice(mg_get(cWin, "invoice_b", "cell", mg_get(cWin,"invoice_b","value"), 1))
//		ONDBLCLICK hb_threadstart(HB_THREAD_INHERIT_PUBLIC, @print_invoice(), mg_get(cWin, "invoice_b", "cell", mg_get(cWin,"invoice_b","value"), 1))

	END BROWSE
	create button edit_b
		row 350
		col 840
		width 160
		height 60
		caption _I("Change item")
		ONCLICK new_item( cWin, .T.)
		tooltip _I("Change item" )
	end button
	create button Del
		row 430
		col 840
		width 160
		height 60
		caption _I("Delete item")
//		backcolor {0,255,0}
		ONCLICK delete_item( cWin, cAll )
		tooltip _I("Delete item")
//    picture cRPath+"task-reject.png"
	end button

	create button Back
		row 510
		col 840
		width 160
		height 60
		caption _I("Back")
//		backcolor {0,255,0}
		ONCLICK mg_do(cWin, "release")
		tooltip _I("Close and go back")
		picture cRPath+"task-reject.png"
	end button

END WINDOW

mg_Do(cWin, "center")
mg_do(cWin, "activate") 

dbcloseall()

return

procedure new_item(cOldW, lEdit)

local cWin := "new_i_w", nUnit := 0, nTax := 0, nType := 0
local aUnit := GetUnit() , aTax := GetTax(), cItemD := "", nPrice := 0.00
local aCat := { "", "Sluzby", "Hardware", "Software" }, aPrice := { 0,0,0,0,0 }
local lInv := .t., lSto := .f., lCR := .f., lTax := TaxStatus(), cEan := ""
local cPic := ""
local lLot := .f., lExp := .f.
local aFullStore := getstore(), aStore := {}, x, nStore
local lInP := .f., lOuP := .f., lPrP := .f., lChP := .f.

field name, price, unit, tax, type, inv_i, sto_i, cr_i, ean, loot, expdate
field t_idn
field pr_price, ch_price, in_price, out_price
default lEdit to .F.

for x := 1 to len( aFullStore )
	aadd( aStore, aFullStore[x][1] )
next

if lEdit
	//x:= mg_get(cOldW, "item_b", "value")
	cItemD := name
	nPrice := price
	nType := aScan( aCat, { | y | alltrim(y) = alltrim(type) } ) 
	nUnit := aScan( aUnit, { |y| alltrim(y) = alltrim(unit) } )
	if lTax
	   nTax := aScan( aTax, { |y| alltrim(y) = strx(tax) } )
	endif
	lInv := inv_i
	lSto := sto_i
	lCR := cr_i
	cEan := ean
	lLot := loot
	lExp := ExpDate
	nStore := aScan( aFullStore, { |y| y[2] = t_idn } )
	lInP := in_price
	lOuP := out_price
	lPrP := ch_price
	lChP := pr_price	
	/*
	for x:=1 to len( aPrice )
		aPrice[x] := fieldget("price"+strx(x))
	next
	*/
endif

create window (cWin)
	row 0
	col 0
	width 1020
	height 450
	CHILD .t.
	MODAL .t.
	if lEdit
		caption _I("Edit item")
	else
		caption _I("New item")
	endif
	CREATE TAB SET
		row 10
		col 10
		width 800
		height 420
		VALUE 1

	CREATE PAGE _I("Basic settings")
		CreateControl(20, 20, cWin, "Itemd", _I("Item Description"), cItemD)
		CreateControl( 20, 560, cWin, "Itemu", _I("Item unit"), aUnit)
		CreateControl( 70, 20, cWin, "Itemp", _I( "Price" ), nPrice )
		if lTax
			CreateControl( 70, 280, cWin, "Itemt", _I( "Tax" ) + " %", aTax )
			CreateControl( 70, 440, cWin, "Itempwt", _I( "Price with Tax" ), 0.00 )
			mg_set(cWin,"Itempwt_t", "readonly", .t. )
		endif
		mg_set(cWin, "Itemd_t", "width", 400)

		CreateControl( 175, 20, cWin, "Cat", _I("Item category"), aCat, .t. )
		CreateControl( 140, 20, cWin, "st", _I("Store"), aStore, .t. )

		if lEdit
			if !empty(nStore)
				mg_set( cWin, "st_c", "value", nStore )
			endif
			mg_set( cWin, "itemu_c", "value", nUnit )
			if lTax
				mg_set( cWin, "itemt_c", "value", nTax )
			endif
			mg_set( cWin, "cat_c", "value", nType )
		endif
		Create CheckBox invoice_c
			row 120
			col 540
			autosize .t.
			Value lInv
			CAPTION _I("Invoice item")
		End CheckBox
		Create CheckBox store_c
			row 150
			col 540
			autosize .t.
			Value lSto
			CAPTION _I("Store item")
			ONCHANGE switch_store( cWin )
		End CheckBox

		Create CheckBox cr_c
			row 180
			col 540
			autosize .t.
			Value lCr
			CAPTION _I("Cash register item")
			ONCHANGE switch_cat( cWin )
		End CheckBox
/*
		create barcode ean_br
			row 200
			col 20
			height 80
			width mg_barcodeGetFinalWidth("123456789012", mg_get( cWin, "ean_br", "type" ), mg_get( cWin, "ean_br", "barwidth" ))
			type "ean13"
			barwidth 2
			backcolor { 255,255,255 }
			value alltrim(mg_get( cWin, "ean_t", "value"))		
			enabled .f.	
		end barcode
*/

		create timer fill_it
			interval	1500
			action fill_it(cWin, aTax, lTax)
			enabled .t.
		end timer
	END PAGE

	CREATE PAGE _I("Advanced settings")

	   CreateControl( 10, 10, cWin, "ean", _I("Ean code"), cEan)
		create button ShowBarcode_b
			row 10
			col 340
			width 140
			height 30
			caption _I("Show barcode")
			//ONCLICK get_picture_file( cWin )
			Onclick show_barcode(mg_get( cWin, "ean_t", "value"))
			tooltip _I( "show barcode" )
		end button
		create button PrintBarcode_b
			row 10
			col 520
			width 140
			height 30
			caption _I("Print barcode")
			ONCLICK get_picture_file( cWin )
			tooltip _I( "Print barcode" )
		end button
	   CreateControl( 70, 10, cWin, "Pic", _I("Item picture"), cPic)

			CREATE BUTTON "get_pic_b"
				ROW 70
				COL 320
				WIDTH 30
				HEIGHT 30
				CAPTION ".."
				TOOLTIP _I( "Upload item picture" )
		//		ONCLICK get_set_File( cWin, "Pic_t" )	
			END BUTTON
			CREATE BUTTON "show_pic_b"
				ROW 70
				COL 365
				WIDTH 140
				Caption _I( "Show picture" )
				TOOLTIP _I( "Show picture" )
				HEIGHT 30
				ONCLICK showimage(mg_get(cWin, "Pic_t", "value"))
			END BUTTON

		Create CheckBox c_lot_c
			row 140
			col 20
			autosize .t.
			Value lLot
			CAPTION _I("Trace item lot No.")
		End CheckBox
		Create CheckBox c_exp_c
			row 180
			col 20
			autosize .f.
			Value lExp
			CAPTION _I("Trace item expiration date and time")
		End CheckBox
	END PAGE
	CREATE PAGE _I("Price settings")
			Create CheckBox linprice_c
			row 20
			col 340
			autosize .t.
			Value lInP
			CAPTION _I("Do not ask for input price")
		End CheckBox
		Create CheckBox loutprice_c
			row 60
			col 340
			autosize .t.
			Value lOuP
			CAPTION _I("Do not ask for selling price")
		End CheckBox

		Create CheckBox lprice_c
			row 100
			col 400
			autosize .t.
			Value lPrP 
			CAPTION _I("Preset selling price")
		End CheckBox
		Create CheckBox lprice_ch_c
			row 140
			col 400
			autosize .t.
			Value lChP
			CAPTION _I("Possibility to change price when dispensing")
		End CheckBox		
		CreateControl( 10, 10, cWin, "Price1", _I( "Price cat  I" ), aPrice[1] )
		CreateControl( 60, 10, cWin, "Price2", _I( "Price cat II" ), aPrice[2] )
		CreateControl(110, 10, cWin, "Price3", _I( "Price cat III" ), aPrice[3] )
		CreateControl(160, 10, cWin, "Price4", _I( "Price cat IV" ), aPrice[4] )
		CreateControl(210, 10, cWin, "Price5", _I( "Price cat V" ), aPrice[5] )
	END PAGE
/*
	create button PrintBarcode_b
		row 160
		col 520
		width 160
		height 60
		caption _I("Print barcode")
		ONCLICK get_picture_file( cWin )
		tooltip _I( "Print barcode" )
	end button
*/
	CreateControl( 240, 820, cWin, "Save",, { || save_item(cWin, aUnit, aTax, aCat, lEdit, cOldW, aFullStore ) } )
	CreateControl( 320, 820, cWin, "Back" )

	END TAB
end window
switch_store(cWin)
switch_cat(cWin)

mg_Do(cWin, "center")
mg_do(cWin, "activate") 

return

static procedure switch_store(cWin)

if mg_get( cWin, "store_c", "value" )
	mg_set( cWin, "st_c", "visible", .t. )
	mg_set( cWin, "st_l", "visible", .t. )
else
	mg_set( cWin, "st_c", "visible", .f. )
	mg_set( cWin, "st_l", "visible", .f. )
endif

return

static procedure switch_cat(cWin)

if mg_get( cWin, "cr_c", "value" )
	mg_set( cWin, "cat_c", "visible", .t. )
	mg_set( cWin, "cat_l", "visible", .t. )
else
	mg_set( cWin, "cat_c", "visible", .f. )
	mg_set( cWin, "cat_l", "visible", .f. )
endif


static procedure save_item( cWin, aUnit, aTax, aType, lEdit, cOldW, aFullStore )

local lTax := TaxStatus()
local aPrn := {}
default lEdit to .f.

if empty(mg_get( cWin, "itemd_t", "value" ))
	msg("Empty item name !?")
	return
endif
if empty(mg_get( cWin, "itemp_t", "value" ))
	msg(_I("Price field is empty!"))
	return
endif

if !lEdit
	if !OpenItems(, 2, .t.)
		return
	endif
endif

if iif( lEdit, reclock(), addrec())
	replace idf with hb_random( 1, 999999 ) 
	replace name with mg_get( cWin, "itemd_t", "value" )
	replace price with mg_get( cWin, "itemp_t", "value" )
	replace unit with aUnit[ mg_get( cWin, "itemu_c", "value" ) ]
	if lTax
		replace tax  with val(aTax[ mg_get( cWin, "itemt_c", "value" ) ])
	endif
	replace type with aType[ mg_get( cWin, "cat_c", "value" ) ]
	replace inv_i with mg_get( cWin, "invoice_c", "value" )
	replace sto_i with mg_get( cWin, "store_c", "value" )
	replace cr_i  with mg_get( cWin, "cr_c", "value" )
	replace ean with mg_get( cWin, "ean_t", "value" )
	replace loot with mg_get( cWin, "c_lot_c", "value" )
	replace expdate with mg_get( cWin, "c_exp_c", "value" )
	replace t_idn with aFullStore[mg_get( cWin, "st_c", "value" )][2]
   replace in_price with mg_get( cWin, "linprice_c", "value" )
   replace out_price with mg_get( cWin, "loutprice_c", "value" )
	replace ch_price with mg_get( cWin, "lprice_ch_c", "value" )
	replace pr_price with mg_get( cWin, "lprice_c", "value" )

	dbrunlock()
/*
   aadd( aPrn, name )
	aadd(	aPrn, "" )
	aadd( aPrn, "Expirace: " + dtos(expdate) )
	aadd( aPrn, "" )
	aadd( aPrn, {idf, .t. })
	send2zebra( aPrn )
*/

endif

if lEdit
	mg_do( cOldW, "item_b", "refresh" )
else
	dbclosearea()
endif

mg_do( cWin, "release" )

return

procedure delete_item( cWin )

local cAll := alias()
field idf

if lastrec() == 0 // .or. empty(idf)
	return
endif

if msgask(_I("Do you really want to delete the item?"))
	if (cAll)->(RecLock())
		(cAll)->(dbdelete())
		(cAll)->(dbrunlock())
		select(cAll)
		mg_do( cWin, "item_b", "refresh" )
		Msg(_I("Item succesfuly removed from database"))
	endif
endif

return

function Get_def_Items( nType, aItems, nStore )

local lAdd, cAl := alias()
field name, unit, price, tax, type, inv_i, sto_i, cr_i, ean, loot, expdate
field t_idn, idf, in_price, out_price

default aItems to {}
default nType to 0
default nStore to 0

if !OpenItems(, 3)
	return aItems
endif

dbgotop()

do while !eof()
	lAdd := .f.
	do case 
	case nType == 0 // in case nType == 0 get all items
		lAdd := .t.
	case nType == 1  // invoice items
		if inv_i
			lAdd := .t.
		endif
	case nType == 2 .or. nType == 3 .or. nType == 5  // stock items
		if sto_i	
			lAdd := .t.
		endif
	case nType == 4 //  cach register items
		if cr_i
			lAdd := .t.	
		endif
	endcase
	if lAdd
		if empty( nStore )
			aadd( aItems, { name, unit, price, tax, 0, 0, 0, ean, loot, expdate,"","","", idf, in_price, out_price } )
		elseif nStore == t_idn			 
			aadd( aItems, { name, unit, price, tax, 0, 0, 0, ean, loot, expdate,"","","", idf, in_price, out_price } )
		endif

	endif
	dbskip()
enddo

dbclosearea()
if !empty(cAl)
	select(cAl)
endif

return aItems


procedure Get_STO_Item(aIt, cOWin, nI, lEdit, nStoreIdf )

local cWin := "add_sto_w", aNames := {}, nNo := 1, x, y
local aUnit := GetUnit() , aTax := GetTax(), nPrice := 0.00, lTax := TaxStatus()
local cEan := "", cLoot := "", dExp := date()
local nUnit, nTax  // cItemd 
local aFullStore := getstore(), nStore
local aFullItems, aItems
local lInPrice := .f., lOutPrice := .f. // default ask for price

default nI to 1
default lEdit to .f.
default nStoreIdf to 0

if mg_iscontrolcreated( cOWin, "store_c" )
	nStore:= aFullStore[ mg_Get( cOWin, "store_c", "value" )][2]
endif

if lEdit
	if empty( aIt )
		return
	endif
	aItems := aIt
	x := mg_get(cOWin, "items_g", "value")
	//cItemD := aIt[x][1]
	nNo := aIt[x][4]
	nPrice := aIt[x][3]
	nUnit := aScan( aUnit, { |y| alltrim(y) = alltrim(aIt[x][2]) } )
   nTax := aScan( aTax, { |y| alltrim(y) = strx(aIt[x][5]) } )
	cEan := aIt[x][8]
	cLoot := aIt[x][9]
	dExp := aIt[x][10]
	//  mg_log(aIt)
else
	aFullItems := get_def_items( nI,, nStore) // show only item's defined to this action
	if empty(aFullItems)
		msg(_I("Unable to find any defined item"+" !?"))
		return
	endif
endif

for y:=1 to len(aFullItems)
	aadd( aNames, aFullItems[y][1] )
next

create window (cWin)
	row 0
	col 0
	width 800
	height 400
	CHILD .t.
	MODAL .t.
	CreateControl( 120, 20, cWin, "Itemp", _I( "Price" ), nPrice )
	CreateControl(70, 310, cWin, "Itemu", _I("Item unit"), aUnit)
   CreateControl( 70, 485, cWin, "EAN", _I("Ean code"), cEan, empty(cEan) )
	CreateControl( 240, 20, cWin, "loot", _I("LOOT No."), cLoot, .t. )
	CreateControl( 285, 20, cWin, "exp", _I("Expiration date"), dExp, .t. )
	
	if lEdit
		if !empty(cLoot)
			mg_set( cWin, "loot_l", "visible", .t. )
			mg_set( cWin, "loot_t", "visible", .t. )
		endif
		if !Empty( dExp )
			mg_set( cWin, "exp_l", "visible", .t. )
			mg_set( cWin, "exp_d", "visible", .t. )
		endif
		mg_set( cWin, "itemu_c", "value", nUnit )
		caption _I("Edit item")
	else
		caption _I("New item")
	//	caption _I("Add item from stock")
	endif

	if lTax
		CreateControl( 120, 280, cWin, "Itemt", _I( "Tax" ) + " %", aTax )
		if lEdit
			mg_set( cWin, "itemt_c", "value", nTax )
		endif
		CreateControl(120, 440, cWin, "Itempwt", _I("Price with Tax"), 0.00)
		CreateControl(190, 20, cWin, "Itemtp", _I("Total price with Tax"), 0.00)
		mg_set(cWin,"Itempwt_t", "readonly", .t. )
		mg_set(cWin,"Itemtp_t", "readonly" , .t. )
	else
		CreateControl(190, 20, cWin, "Itemtp", _I("Total price"), 0.00)
		mg_set(cWin,"Itemtp_t", "readonly" , .t. )
	endif

	//CreateControl(20, 20, cWin, "Itemd", _I("Item Description"), cItemD)
	create combobox itemget_c
		row 20
		col 20
		width 550
		height 30
		//autosize .t.
		items aNames
		onchange fill_cho( cWin, aItems, aTax, aUnit, lTax, lEdit, aFullItems )
		DISPLAYEDIT .T.
		if lEdit
			value x
		else
			value 1
		endif
	end combobox	
   create label itemq_l
	   row 75
      col 20
		autosize .t.
      value _I("Quantity")
	end label	
   CREATE SPINNER itemq_t
		row 70
		col 110
		width 100
		height 30
		rangemin 1
		rangemax 99999
		value nNo
	//	autosize .t.
	end spinner
	// CreateControl(70, 20, cWin, "Itemq", _I("Quantity"), nNo)

/*
	create barcode ean_br
		row 180
		col 460
		height 60
		width mg_barcodeGetFinalWidth("123456789012", mg_get( cWin, "ean_br", "type" ), mg_get( cWin, "ean_br", "barwidth" ))
		type "ean13"
		barwidth 2
		backcolor { 255,255,255 }
		value alltrim(mg_get( cWin, "ean_t", "value"))		
		enabled .f.
	end barcode
*/

	create timer fill_choice
		interval	500
		action fill_it( cWin, aTax, lTax )
		enabled .t.
	end timer
	mg_do( cWin, "itemq_t", "setfocus" )
	CreateControl(240, 610, cWin, "Save",, {|| fill_item(@aIt, cWin, cOWin, aTax, lTax, x, aFullItems )})
	CreateControl(320, 610, cWin, "Back")
end window

mg_Do(cWin, "center")
mg_do(cWin, "activate") 

return

procedure fill_cho(cWin, aArr, aTax, aUnit, lTax, lEdit, aFullItems )

local nTax, nX := mg_get(cWin, "Itemget_c", "value"), nUnit, nPr

//nPr := aArr[nX][3]
nPr := aFullItems[nX][3]
 
mg_set( cWin, "itemp_t", "value", nPr ) // set price from item
nUnit := aScan( aUnit, { |y| alltrim(y) = alltrim(aFullItems[nX][2]) } )
mg_set( cWin, "itemu_c", "value", nUnit )
//mg_set( cWin, "ean_t", "value", alltrim(aArr[nX][8]))

if aFullItems[nX][9]
	//mg_do( cWin, "loot_l", "enable" )
endif

if lEdit
//	mg_set( cWin, "loot_t", "value", alltrim(aArr[nX][9]))
//	mg_set( cWin, "exp_d", "value", alltrim(aArr[nX][10]))
else
	if lTax
		nTax := aScan( aTax, { |y| alltrim(y) = strx(aFullItems[nX][4]) } )
		mg_set( cWin, "itemt_c", "value", nTax )
	endif
	mg_set( cWin, "loot_l", "visible", aFullItems[nX][9] )
	mg_set( cWin, "loot_t", "visible", aFullItems[nX][9] )
	mg_set( cWin, "exp_l", "visible", aFullItems[nX][10] )
	mg_set( cWin, "exp_d", "visible", aFullItems[nX][10] )
	if !aFullItems[nX][15] 
		mg_set( cWin, "itemp_l", "visible", .F. )
		mg_set( cWin, "itemp_t", "visible", .F. )
		mg_set( cWin, "itemtp_l", "visible", .F. )
		mg_set( cWin, "itemtp_t", "visible", .F. )
		mg_set( cWin, "itempwt_l", "visible", .F. )
		mg_set( cWin, "itempwt_t", "visible", .F. )
		mg_set( cWin, "itemt_l", "visible", .F. )
		mg_set( cWin, "itemt_c", "visible", .F. )
	ENDIF

endif

return

function fill_item( aIt, cWin, cPWin, aTax, lTax, nX, aFullItems)

local nPrice := mg_get(cWin, "Itemp_t", "value")
local nQ := mg_get(cWin, "Itemq_t", "value")
local nTax := 0, cName, lEdit
local aUnit := GetUnit()
local nGet := mg_get(cWin, "Itemget_c", "value")

default nX to 0

if nX == 0
	lEdit := .F.
else
	lEdit := .T.
endif

if empty( mg_getControlParentType( cWin, "Itemd_t" ) )
	cName := mg_get(cWin, "Itemget_c", "displayValue")
else
 	cName := mg_get(cWin, "Itemd_t", "Value")
endif
if empty(nPrice) .or. empty(nQ) .or. empty(cName)
	msg(_I("Please fill some more information"))
	return aIt
endif

if mg_get( cWin, "loot_t", "visible" ) .and.  empty( mg_get( cWin, "loot_t", "value" ) )
	msg( _I( "Please fill Loot No." ) )
	return aIt
endif

if mg_get( cWin, "exp_d", "visible" ) .and.  (mg_get( cWin, "exp_d", "value" ) <= date())
	msg( _I( "Please fill expiration date" ) )
	return aIt
endif

if lTax
	nTax := val(aTax[mg_get(cWin, "Itemt_c", "value")])
	if lEdit
		aIt[nX] := { cName, ;
						aUnit[mg_get(cWin, "Itemu_c", "value")], ;
 						mg_get(cWin, "Itemp_t", "value"), ;	
						mg_get(cWin, "Itemq_t", "value"), ;	
						nTax, ;
						round((nPrice * nQ), 2), ;
						round((nPrice * nQ * (1+nTax/100)), 2), ;
						mg_get( cWin, "ean_t", "value" ),       ;
						mg_get( cWin, "loot_t", "value" ),      ;
						mg_get( cWin, "exp_d", "value"),         ;
						aFullItems[nGet][14] } 

						
	else
		//mg_log( nX )
		//mg_log( aFullItems )
		aadd( aIt, { cName, ;
						aUnit[mg_get(cWin, "Itemu_c", "value")], ;
 						mg_get(cWin, "Itemp_t", "value"), ;	
						mg_get(cWin, "Itemq_t", "value"), ;	
						nTax, ;
						round((nPrice * nQ), 2), ;
						round((nPrice * nQ * (1+nTax/100)), 2), ; 
						mg_get( cWin, "ean_t", "value" ),       ;
						mg_get( cWin, "loot_t", "value" ),      ;
						mg_get( cWin, "exp_d", "value" ),       ;
						aFullItems[nGet][14] } )
					
	endif	
else
	if lEdit
		aIt[nX] := { cName, ;
						aUnit[mg_get(cWin, "Itemu_c", "value")], ;
 						mg_get(cWin, "Itemp_t", "value"), ;	
						mg_get(cWin, "Itemq_t", "value"), ;	
						nTax, ;
                  round((nPrice * nQ), 2),  ;
                  round( nPrice * nQ, 2 ), ;
						mg_get( cWin, "ean_t", "value" ),       ;
						mg_get( cWin, "loot_t", "value" ),      ;
						mg_get( cWin, "exp_d", "value"),        ;
						aFullItems[nGet][14] } 

	else
		aadd( aIt, { cName, ;
						aUnit[mg_get(cWin, "Itemu_c", "value")], ;
 						mg_get(cWin, "Itemp_t", "value"), ;	
						mg_get(cWin, "Itemq_t", "value"), ;	
						nTax,  ;
                  round((nPrice * nQ), 2), ;
                  round( nPrice * nQ, 2 ), ;
						mg_get( cWin, "ean_t", "value" ),       ;
						mg_get( cWin, "loot_t", "value" ),      ;
						mg_get( cWin, "exp_d", "value" ) ,      ;
						aFullItems[nGet][14] } )


	endif
endif
	
mg_do(cPWin, "items_g", "refresh")
mg_do(cWin, "release")

return aIt

procedure fill_it(cWin, aTax, lTax, lEan)

local nPr := mg_get(cWin, "Itemp_t", "value")
//local cEan
local nTax := 0

default lTax to .t.
default lEan to .t.

if lTax
	nTax := val(aTax[mg_get(cWin, "Itemt_c", "value")])
endif
if !empty(nPr)
	if !empty( mg_getControlParentType( cWin, "Itempwt_t" ) )
		mg_set(cWin,"Itempwt_t", "value", round( nPr * ( nTax/100+1 ), 2 ) )
	endif
	if !empty( mg_getControlParentType( cWin, "Itemtp_t" ) )
		if lTax
			mg_set(cWin,"Itemtp_t", "value", round( nPr * ( nTax/100+1 ), 2 ) *  mg_get(cWin, "Itemq_t", "value" ))
		else
 			mg_set(cWin,"Itemtp_t", "value", round( nPr, 2 ) * mg_get(cWin, "Itemq_t", "value" )) 
		endif
	endif
endif

/*
if lEan
	cEan := alltrim(mg_get(cWin, "ean_t", "value"))
	if len(cEan) >=12
		mg_set( cWin, "ean_br", "visible", .t.)
	else
		mg_set( cWin, "ean_br", "visible", .f.)
	endif
endif
*/

return

function get_picture_file( )

local cFile

cFile := mg_GetFile( { { "All Files", mg_GetMaskAllFiles() }}, "Select File",,, .t. )

return cFile

static procedure show_barcode( cTxt )

local cWin := "WinFullBarcode"

cTxt := alltrim(cTxt)
if len(cTxt) <> 12
	Msg(_I("EAN13 Code must contain 12 characters. Please try again."))
//	mg_log(len(cTxt))
	return
endif

  CREATE WINDOW (cWin)
      ROW 0
      COL 0
      CAPTION "Barcode"
      MODAL .T.

      CREATE Barcode FullImage
         ROW 15
         COL 15
			TYPE "EAN13"
			barwidth 2
			HEIGHT 80
         WIDTH mg_barcodeGetFinalWidth("123456789012", mg_get( cWin, "FullImage", "type" ), mg_get( cWin, "FullImage", "barwidth" ))
			BACKCOLOR { 255, 255, 255 }
			VALUE cTxt
//         WIDTH mg_get( cWin, "FullImage" , "realWidth" )
//         HEIGHT mg_get( cWin , "FullImage" , "realHeight" )
			
         //STRETCH .T.
      END BARCODE

//      WIDTH mg_get( cWin, "FullImage" , "width" )
//      HEIGHT mg_get( cWin,  "FullImage" , "height" )
		WIDTH 220
      HEIGHT 120 

   END WINDOW

   mg_do( cWin, "center" )
   mg_do( cWin, "activate" )

return





