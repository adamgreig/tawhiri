$('[data-toggle="offcanvas"]').click ->
    $('.row-offcanvas').toggleClass 'active'

$('.unit-selector .dropdown-menu li a').click (event) ->
    event.preventDefault();
    unit = $(this)
    unit_sel = unit.closest '.unit-selector'
    unit_sel.find('.unit-current').html(unit.html())
    unit_sel.find('input[type=hidden]').val(unit.html())
    unit_sel.click()
    return false

$('#launch-date').datetimepicker
    format: "HH:mm, D MMM YYYY",
    stepping: 5,
    minDate: Date.now(),
    maxDate: Date.now() + 7*24*60*60*1000,
    showTodayButton: true,
    showClose: true

date = new Date()
$('#launch-utc-offset').val date.getTimezoneOffset()/60
