import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "error", "submit"]

  connect() {
    this.validate()
  }

  validate() {
    if (this.inputTarget.value.trim().length > 0) {
      this.hideError()
      this.enableSubmit()
    } else {
      this.showError()
      this.disableSubmit()
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