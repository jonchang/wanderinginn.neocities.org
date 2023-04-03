#[macro_use]
extern crate lazy_static;
use anyhow::Result;
use glob::glob;
use html5ever::rcdom::{RcDom, Node, NodeData};
use html5ever::{ParseOpts, parse_document};
use indicatif::ParallelProgressIterator;
use rayon::iter::{IntoParallelRefIterator, ParallelIterator};
use readability::extractor;
use regex::Regex;
use std::fs::{create_dir_all, File};
use std::io::Write;
use std::path::{Path, PathBuf};
use tendril::TendrilSink;
use url::Url;

// Code from dissolve rust crate
// https://github.com/KiChjang/dissolve/blob/master/src/lib.rs
// MIT license
/// Consumes a string that contains HTML5 tags and outputs a Vec<String>
/// containing the text content inside the tags in a pre-order manner.
///
/// Basic usage:
///
/// ```rust
/// let input = "<html>Hello World!</html>";
/// let output = strip_html_tags(input);
/// assert_eq!(output, vec!["Hello World!".to_owned()]);
/// ```
pub fn strip_html_tags(input: &str) -> Vec<String> {
    let dom = parse_document(RcDom::default(), ParseOpts::default())
        .from_utf8()
        .one(input.as_bytes());
    let doc = dom.document;
    get_text(&doc)
}

/// Helper function to return text in text nodes in pre-order traversal.
fn get_text(element: &Node) -> Vec<String> {
    match element.data {
        NodeData::Text { ref contents } => {
            let mut text = vec!((&**contents.borrow()).to_owned());
            for child in &*element.children.borrow() {
                text.append(&mut get_text(child));
            }
            text
        }
        _ => {
            let mut text = vec!();
            for child in &*element.children.borrow() {
                text.append(&mut get_text(child));
            }
            text
        }
    }
}

fn fix_text(text: String) -> String {
    lazy_static! {
        static ref RE1: Regex =
            Regex::new(r"Previous Chapter|Next Chapter|</?span>|</p>|</?em>").unwrap();
        static ref RE2: Regex = Regex::new(r"\n{3,}").unwrap();
    }
    strip_html_tags(
        &RE2.replace_all(
            &RE1.replace_all(&text, "")
                .replace("<p>", "\n\n")
                .replace("\u{A0}", " ")
                .replace("&nbsp;", " "),
            "\n\n",
        ),
    )
    .join("")
    .trim()
    .to_string()
}

fn get_datestamp(file: &str) -> &str {
    lazy_static! {
        static ref RE: Regex = Regex::new(r"\d{14}").unwrap();
    }
    RE.find(file).expect("No datestamp found").as_str()
}

fn get_slug(file: &PathBuf) -> &str {
    file.parent()
        .expect("No parent found!")
        .components()
        .last()
        .expect("No last component!")
        .as_os_str()
        .to_str()
        .expect("Couldn't convert to str")
}

fn do_extract<P: AsRef<Path>>(file: P) -> String {
    let mut fh = File::open(&file).expect("Failed to open file");
    let mut url = Url::parse("http://wanderinginn.com").expect("Parsing error");
    fix_text(
        extractor::extract(&mut fh, &mut url)
            .expect("Failed to extract text")
            .content,
    )
}

fn write_to_path(text: &str, slug: &str, datestamp: &str) {
    let mut path: PathBuf = ["texts", slug].iter().collect();
    create_dir_all(&path).expect("Create path failed");
    path.push(format!("{}.txt", datestamp));
    let mut outfile = File::create(path).expect("Create file failed");
    outfile.write_all(text.as_bytes()).expect("Write failed");
}

fn main() -> Result<()> {
    let files: Vec<_> = glob("websites/**/index.html")?
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
