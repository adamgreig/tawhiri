UIMod.BalloonMod.view = ->
        [
         # Mode
         (m '.form-group', [
             (m 'label.control-label.col-sm-4[for=inp-mode]', 'Mode'),
             (m '.col-sm-8', [
                 (m '.btn-group', [
                     (m 'button.btn.btn-default.dropdown-toggle
                         [type=button][data-toggle=dropdown]
                         [aria-expanded=false]', ['Standard ', m 'span.caret']),
                     (m 'ul.dropdown-menu[role=menu]', [
                         (m 'li', m 'a[href=#]', 'Standard'),
                         (m 'li.disabled', m 'a[href=#]', ['Standard ', m.trust('&plusmn;'), '% scatter']),
                         (m 'li.disabled', m 'a[href=#]', 'Standard min-max scatter'),
                         (m 'li.disabled', m 'a[href=#]', 'Hourly'),
                     ]),
                 ]),
                 ' ',
                 (m 'button.btn.btn-default.hide
                     [type=button][title="Choose hours for hourly prediction"]',
                    m 'span.glyphicon.glyphicon-time'),
             ]),
         ]),
         
         # Burst Alt / Float Alt / Payload Mass
         (m '.form-group', [
             (m '.col-sm-4', m '.btn-group.pull-right', [
                 (m 'button.btn.btn-default.dropdown-toggle.dropdown-label
                     [type=button][data-toggle=dropdown][aria-expanded=false]',
                     'Burst Alt'),
                 (m 'ul.dropdown-menu[role=menu]', [
                     (m 'li', m 'a[href=#]', 'Burst Alt'),
                     (m 'li.disabled', m 'a[href=#]', 'Float Alt'),
                     (m 'li.disabled', m 'a[href=#]', 'Payload Mass'),
                 ]),
             ]),
             (m '.col-sm-8', m '.input-group', [
                 (m 'input.form-control#inp-bfp-val[required][type=number][step=any]',
                    value: ConfigVM.bfp_val(),
                    onchange: m.withAttr 'value', ConfigVM.bfp_val
                 ),
                 (m '.input-group-btn', [
                     (m 'button.btn.btn-default.dropdown-toggle
                         [type=button][data-toggle=dropdown]',
                         (m 'span.current-unit', 'km')),
                     (m 'ul.dropdown-menu.dropdown-menu-right.dropdown-menu-units', [
                         (m 'li', m 'a[href=#]', 'km'),
                         (m 'li.disabled', m 'a[href=#]', 'kft'),
                         (m 'li.divider.hide'),
                         (m 'li.hide', m 'a[href=#]', m.trust('&plusmn;0%')),
                         (m 'li.hide', m 'a[href=#]', m.trust('&plusmn;5%')),
                         (m 'li.hide', m 'a[href=#]', m.trust('&plusmn;10%')),
                         (m 'li.hide', m 'a[href=#]', m.trust('&plusmn;15%')),
                         (m 'li.hide', m 'a[href=#]', m.trust('&plusmn;20%')),
                     ]),
                 ]),
             ]),
         ]),

         # Balloon choice
         (m '.form-group.hide', [
             (m 'label.control-label.col-sm-4[for=inp-bm]', 'Balloon'),
             (m '.col-sm-8', m '.input-group', [
                 (m 'button.btn.btn-default.dropdown-toggle
                     [type=button][data-toggle=dropdown][disabled]', 'Hwoyee 600g'),
                 (m 'ul.dropdown-menu.dropdown-menu-right', [
                     (m 'li', m 'a[href=#]', 'Hwoyee 100g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 200g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 300g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 350g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 400g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 500g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 600g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 750g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 800g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 950g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 1000g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 1200g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 1500g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 1600g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 2000g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 3000g'),
                 ]),
             ]),
         ]),

         # Ascent Rate / Burst Altitude
         (m '.form-group', [
             (m '.col-sm-4', m '.btn-group.pull-right', [
                 (m 'button.btn.btn-default.dropdown-toggle.dropdown-label
                     [type=button][data-toggle=dropdown][aria-expanded=false]',
                     'Ascent Rate'),
                 (m 'ul.dropdown-menu[role=menu]', [
                     (m 'li', m 'a[href=#]', 'Ascent Rate'),
                     (m 'li.hide', m 'a[href=#]', 'Burst Alt'),
                 ]),
             ]),
             (m '.col-sm-8', m '.input-group', [
                 (m 'input.form-control#inp-ar
                     [required][type=number][placeholder=""][step=any]',
                     value: ConfigVM.ascent_rate(),
                     onchange: m.withAttr 'value', ConfigVM.ascent_rate),
                 (m 'input.form-control.hide#inp-ar-min
                     [required][type=number][placeholder=""][step=any]'),
                 (m 'input.form-control.hide#inp-ar-max
                     [required][type=number][placeholder=Max][step=any]'),
                 (m '.input-group-btn.unit-selector', [
                     (m 'button.btn.btn-default.dropdown-toggle
                         [data-toggle=dropdown][type=button]',
                         (m 'span.current-unit', 'm/s')),
                     (m 'ul.dropdown-menu.dropdown-menu-right.dropdown-menu-units', [
                         (m 'li', m 'a[href=#]', 'm/s'),
                         (m 'li.disabled', m 'a[href=#]', 'ft/s'),
                         (m 'li.divider.hide'),
                         (m 'li.hide', m 'a[href=#]', m.trust('&plusmn;0%')),
                         (m 'li.hide', m 'a[href=#]', m.trust('&plusmn;5%')),
                         (m 'li.hide', m 'a[href=#]', m.trust('&plusmn;10%')),
                         (m 'li.hide', m 'a[href=#]', m.trust('&plusmn;15%')),
                         (m 'li.hide', m 'a[href=#]', m.trust('&plusmn;20%')),
                     ]),
                 ]),
             ]),
         ]),
        ]
