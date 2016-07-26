"use strict";

let gulp = require('gulp');
let pug = require('gulp-pug');
let sourcemaps = require('gulp-sourcemaps');
let frontmatter = require('gulp-front-matter');
let markdown = require('gulp-markdown');
let uglify = require('gulp-uglify');
let postcss = require('gulp-postcss');
let postcssImport = require('postcss-import');
let precss = require('precss');
let autoprefixer = require('autoprefixer');
let cssnano = require('cssnano');
let through = require('through2');

let template = (name) => {
	let pug = require('pug');

	return through.obj(function(file, enc, cb) {
		let data = {
			contents: file.contents,
			page: file.page
		};
		file.contents = new Buffer(pug.renderFile(`templates/${name}.pug`, data), 'utf8');
		this.push(file);
		cb();
	});
}

gulp.task('articles', () =>
	gulp.src(['content/articles/*.md'])
		.pipe(frontmatter({
			property: 'page',
			remove: true
		}))
		.pipe(markdown())
		.pipe(template('base'))
		.pipe(gulp.dest('build/content/articles/'))
);

gulp.task('content', () =>
	gulp.src(['content/**/*.pug'])
		.pipe(pug())
		.pipe(gulp.dest('build/content/'))
);

gulp.task('scripts', () =>
	gulp.src('node_modules/reveal.js/js/reveal.js')
		.pipe(sourcemaps.init())
		.pipe(uglify())
		.pipe(sourcemaps.write('.'))
		.pipe(gulp.dest('build/static/scripts/'))
);

gulp.task('styles', () =>
	gulp.src(['static/styles/reveal.css'])
		.pipe(sourcemaps.init())
		.pipe(postcss([
			postcssImport(),
			precss(),
			autoprefixer(),
			cssnano()
		]))
		.pipe(sourcemaps.write('.'))
		.pipe(gulp.dest('build/static/styles/'))
);

gulp.task('watch', gulp.parallel('content', 'scripts', 'styles', 'articles', () => {
	gulp.watch(['content/**/*.jade'], gulp.series('content'));
	gulp.watch(['static/styles/**/*.css'], gulp.series('styles'));
	//gulp.watch(['static/scripts/**/*.js'], ['scripts']);
}));

gulp.task('default', gulp.parallel('content', 'scripts', 'styles', 'articles'));
