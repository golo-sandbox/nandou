module nandou.String

augment java.lang.String {
    #interpolate
	function fitin = |this, dataName, data| {
		let tpl = gololang.TemplateEngine(): compile("<%@params "+dataName+" %> "+this)
		return tpl(data)
	}
}



