import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "error", "submit"]

  connect() {
    console.log("Disclaimer step controller connected")
    this.validate()
  }

  disconnect() {
    console.log("Disclaimer step controller disconnected")
  }

  toggle() {
    console.log("Checkbox toggled, checked:", this.checkboxTarget.checked)
    this.validate()
  }

  validate() {
    console.log("Validating disclaimer step, checkbox checked:", this.checkboxTarget.checked)
    if (this.checkboxTarget.checked) {
      this.hideError()
      this.enableSubmit()
    } else {
      this.showError()
      this.disableSubmit()
    }
  }

  showError() {
    console.log("Showing error")
    this.errorTarget.style.display = "block"
  }

  hideError() {
    console.log("Hiding error")
    this.errorTarget.style.display = "none"
  }

  disableSubmit() {
    this.submitTarget.disabled = true
    this.submitTarget.classList.add("opacity-50", "cursor-not-allowed")
  }

  enableSubmit() {
    this.submitTarget.disabled = false
    this.submitTarget.classList.remove("opacity-50", "cursor-not-allowed")
  }
} 