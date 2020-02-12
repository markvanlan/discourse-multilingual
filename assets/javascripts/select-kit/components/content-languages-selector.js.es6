import MultiSelectComponent from "select-kit/components/multi-select";

export default MultiSelectComponent.extend({
  classNames: ['content-languages-selector', 'classNames'],
  allowAny: false,
  valueProperty: "code",
  nameProperty: "name",
  options: {
    filterable: true
  },
  initializeContentLanguges: true,
  
  didInsertElement() {
    this._super(...arguments);
    
    console.log(this.currentUser.content_languages)
        
    if (!this.value
        && this.initializeContentLanguges
        && this.currentUser.content_languages.length) {
      this.set('value', this.currentUser.content_languages[0].code)
    }
  }
});