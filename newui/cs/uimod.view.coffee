UIMod.view = ->
    m 'form.form-horizontal', [
        UIMod.LocationMod.view(),
        UIMod.TimeMod.view(),
        UIMod.BalloonMod.view(),
        m '.form-group',
            m '.col-sm-8.col-sm-offset-2',
                m 'button.btn.btn-lg.btn-success#runpred[type=button]', 'Run Prediction'
    ]
