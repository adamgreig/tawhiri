$('.unit-selector .dropdown-menu li a').click (event) ->
    event.preventDefault();
    unit = $(this)
    unit_sel = unit.closest '.unit-selector'
    unit_sel.find('.unit-current').html(unit.html())
    unit_sel.find('input[type=hidden]').val(unit.html())
    unit_sel.click()
    return false

