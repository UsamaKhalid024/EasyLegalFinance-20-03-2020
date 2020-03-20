import { LightningElement, api } from 'lwc';
//import html from './textAsHtml.html';

export default class TextAsHtml extends LightningElement {
    @api html;

    /*
    renderedCallback() {
        //return `<template>${this.html}</template>`
        const span = this.template.querySelector('span.span');
        span.appendChild(this.html);
        //let html = new DOMParser().parseFromString( this.html, 'text/html');
        //return Array.from(html.body.childNodes);
        //return html
    }
    */
}