var gulp = require('gulp');
var browserSync = require('browser-sync');
var concat = require('gulp-concat');
var coffee = require('gulp-coffee');
var coffeelint = require('gulp-coffeelint');

var coffee_files = [
    './cs/configvm.coffee',
    './cs/**/*.model.coffee',
    './cs/**/*.controller.coffee',
    './cs/**/*.view.coffee',
    './cs/app.coffee'
];

gulp.task('default', function() {
});

gulp.task('lint', function() {
    gulp.src('./cs/**/*.coffee')
        .pipe(coffeelint())
        .pipe(coffeelint.reporter())
});

gulp.task('coffee', function() {
    return gulp.src(coffee_files)
        .pipe(concat('tawhiri.coffee'))
        .pipe(coffee())
        .pipe(gulp.dest('./'))
});

gulp.task('coffee-watch', ['coffee'], browserSync.reload);

gulp.task('serve', ['coffee'], function() {
    browserSync({
        server: {
            baseDir: './'
        }
    });

    gulp.watch(coffee_files, ['coffee-watch']);
});
