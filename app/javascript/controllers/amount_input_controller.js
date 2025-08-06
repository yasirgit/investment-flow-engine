import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "error", "submit"]

  connect() {
    this.validate()
  }

  validate() {
    const value = parseFloat(this.inputTarget.value)
    const min = parseFloat(this.inputTarget.min)
    const max = parseFloat(this.inputTarget.max)
    
    if (isNaN(value) || value < min || value > max) {
      this.showError()
      this.disableSubmit()
    } else {
      this.hideError()
      this.enableSubmit()
    }
  }

  showError() {
    this.errorTarget.classList.remove("hidden")
  }

  hideError() {
    this.errorTarget.classList.add("hidden")
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