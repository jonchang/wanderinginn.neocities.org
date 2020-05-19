#[macro_use] extern crate lazy_static;
use exitfailure::ExitFailure;
use glob::glob;
use readability::extractor;
use regex::Regex;
use std::fs::{File, create_dir_all};
use std::io::Write;
use std::path::{PathBuf, Path};
use url::Url;
use indicatif::ParallelProgressIterator;
use rayon::iter::{ParallelIterator, IntoParallelRefIterator};
use dissolve::strip_html_tags;

fn fix_text(text: String) -> String {
    lazy_static! {
        static ref RE1: Regex = Regex::new(r"Previous Chapter|Next Chapter|</?span>|</p>|</?em>").unwrap();
        static ref RE2: Regex = Regex::new(r"\n{3,}").unwrap();
    }
    strip_html_tags(&RE2.replace_all(&RE1.replace_all(&text, "")
                                     .replace("<p>", "\n\n")
                                     .replace("\u{00A0}", " "), "\n\n")).join("").trim().to_string()
}

fn get_datestamp(file: &str) -> &str {
    lazy_static! {
        static ref RE: Regex = Regex::new(r"\d{14}").unwrap();
    }
    RE.find(file).expect("No datestamp found").as_str()
}

fn get_slug(file: &PathBuf) -> &str {
    file.parent().expect("No parent found!").components().last().expect("No last component!").as_os_str().to_str().expect("Couldn't convert to str")
}

fn do_extract<P: AsRef<Path>>(file: P) -> String {
    let mut fh = File::open(&file).expect("Failed to open file");
    let mut url =  Url::parse("http://wanderinginn.com").expect("Parsing error");
    fix_text(extractor::extract(&mut fh, &mut url).expect("Failed to extract text").content)
}

fn write_to_path(text: &str, slug: &str, datestamp: &str) {
    let mut path: PathBuf = ["texts", slug].iter().collect();
    create_dir_all(&path).expect("Create path failed");
    path.push(format!("{}.txt", datestamp));
    let mut outfile = File::create(path).expect("Create file failed");
    outfile.write_all(text.as_bytes()).expect("Write failed");
}


fn main() -> Result<(), ExitFailure> {
    let files: Vec<_> = glob("/Users/jonchang/TWI/websites/**/index.html")?
        .filter_map(|x| x.ok())
        .collect();

    let ln: u64 = files.len() as u64;

    files.par_iter().progress_count(ln).for_each(move |file| {
        let datestamp = get_datestamp(file.to_str().expect("Couldn't get filename"));
        let slug = get_slug(&file);
        let text = do_extract(&file);
        if !text.is_empty() {
            write_to_path(text.as_str(), slug, datestamp);
        }
    });

    Ok(())
}
