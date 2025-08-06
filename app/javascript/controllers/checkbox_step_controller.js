import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "error", "submit"]

  connect() {
    console.log("=== CHECKBOX CONTROLLER CONNECTED ===")
    console.log("Controller element:", this.element)
    console.log("Has checkbox target:", this.hasCheckboxTarget)
    console.log("Has error target:", this.hasErrorTarget)
    console.log("Has submit target:", this.hasSubmitTarget)
    
    // Test if we can find the checkbox
    const checkbox = this.element.querySelector('input[type="checkbox"]')
    console.log("Found checkbox:", checkbox)
    if (checkbox) {
      console.log("Checkbox checked:", checkbox.checked)
    }
  }

  disconnect() {
    console.log("=== CHECKBOX CONTROLLER DISCONNECTED ===")
  }

  toggle() {
    console.log("=== CHECKBOX TOGGLED ===")
    if (this.hasCheckboxTarget) {
      console.log("New checked state:", this.checkboxTarget.checked)
      this.validate()
    }
  }

  validate() {
    console.log("=== VALIDATING CHECKBOX ===")
    if (!this.hasCheckboxTarget) {
      console.log("No checkbox target found")
      return
    }
    
    console.log("Checkbox checked:", this.checkboxTarget.checked)
    
    if (this.checkboxTarget.checked) {
      console.log("Checkbox is checked - hiding error and enabling submit")
      this.hideError()
      this.enableSubmit()
    } else {
      console.log("Checkbox is unchecked - showing error and disabling submit")
      this.showError()
      this.disableSubmit()
    }
  }

  showError() {
    console.log("Showing error message")
    if (this.hasErrorTarget) {
      this.errorTarget.style.display = "block"
      this.errorTarget.style.color = "red"
    }
  }

  hideError() {
    console.log("Hiding error message")
    if (this.hasErrorTarget) {
      this.errorTarget.style.display = "none"
    }
  }

  disableSubmit() {
    console.log("Disabling submit button")
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
      this.submitTarget.classList.add("opacity-50", "cursor-not-allowed")
    }
  }

  enableSubmit() {
    console.log("Enabling submit button")
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = false
      this.submitTarget.classList.remove("opacity-50", "cursor-not-allowed")
    }
  }
} 