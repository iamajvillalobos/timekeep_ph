import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ 
    "video", "canvas", "placeholder", "startButton", "captureButton", "retakeButton", 
    "gpsStatus", "latInput", "lngInput", "selfieInput", "submitButton", 
    "branchSelect", "form" 
  ]

  connect() {
    console.log("Clock-in controller connected")
    this.stream = null
    this.hasLocation = false
    this.hasSelfie = false
    
    // Get GPS location on connect
    this.getLocation()
    
    // Add form submission handler
    this.formTarget.addEventListener('ajax:success', this.handleSuccess.bind(this))
    this.formTarget.addEventListener('ajax:error', this.handleError.bind(this))
  }

  disconnect() {
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop())
    }
  }

  async startCamera() {
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ 
        video: { 
          facingMode: "user",  // Front-facing camera for selfies
          width: { ideal: 640 },
          height: { ideal: 480 }
        } 
      })
      
      this.videoTarget.srcObject = this.stream
      
      // Show video, hide placeholder
      this.placeholderTarget.classList.add("hidden")
      this.videoTarget.classList.remove("hidden")
      
      // Update buttons
      this.startButtonTarget.classList.add("hidden")
      this.captureButtonTarget.classList.remove("hidden")
      
    } catch (error) {
      console.error("Camera access error:", error)
      this.showError("Camera access denied. Please allow camera permissions.")
    }
  }

  takeSelfie() {
    const video = this.videoTarget
    const canvas = this.canvasTarget
    
    // Set canvas dimensions to match video
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    
    // Draw video frame to canvas
    const ctx = canvas.getContext('2d')
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
    
    // Convert to base64
    const selfieData = canvas.toDataURL('image/jpeg', 0.8)
    this.selfieInputTarget.value = selfieData
    
    // Show canvas, hide video
    this.videoTarget.classList.add("hidden")
    this.canvasTarget.classList.remove("hidden")
    
    // Update buttons
    this.captureButtonTarget.classList.add("hidden")
    this.retakeButtonTarget.classList.remove("hidden")
    
    // Stop camera stream
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop())
      this.stream = null
    }
    
    this.hasSelfie = true
    this.updateSubmitButton()
    
    // Lock branch selector after selfie is taken (but keep it enabled for form submission)
    this.branchSelectTarget.classList.add("bg-gray-100", "cursor-not-allowed")
    this.branchSelectTarget.style.pointerEvents = "none"
  }

  retakeSelfie() {
    // Clear selfie data
    this.selfieInputTarget.value = ""
    this.hasSelfie = false
    
    // Hide canvas, show placeholder
    this.canvasTarget.classList.add("hidden")
    this.placeholderTarget.classList.remove("hidden")
    
    // Reset buttons
    this.retakeButtonTarget.classList.add("hidden")
    this.startButtonTarget.classList.remove("hidden")
    
    // Unlock branch selector
    this.branchSelectTarget.classList.remove("bg-gray-100", "cursor-not-allowed")
    this.branchSelectTarget.style.pointerEvents = "auto"
    
    this.updateSubmitButton()
  }

  getLocation() {
    this.gpsStatusTarget.textContent = "Getting location..."
    
    if (!navigator.geolocation) {
      this.showLocationError("Geolocation not supported")
      return
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.latInputTarget.value = position.coords.latitude
        this.lngInputTarget.value = position.coords.longitude
        this.hasLocation = true
        
        this.gpsStatusTarget.textContent = `Located (${position.coords.latitude.toFixed(4)}, ${position.coords.longitude.toFixed(4)})`
        this.gpsStatusTarget.parentElement.classList.remove("bg-blue-50", "border-blue-200")
        this.gpsStatusTarget.parentElement.classList.add("bg-green-50", "border-green-200")
        
        this.updateSubmitButton()
      },
      (error) => {
        console.error("Geolocation error:", error)
        this.showLocationError("Location access denied")
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 300000 // 5 minutes
      }
    )
  }

  showLocationError(message) {
    this.gpsStatusTarget.textContent = message
    this.gpsStatusTarget.parentElement.classList.remove("bg-blue-50", "border-blue-200")
    this.gpsStatusTarget.parentElement.classList.add("bg-red-50", "border-red-200")
  }

  showError(message) {
    // Create flash message
    const flashContainer = document.createElement('div')
    flashContainer.className = "max-w-md mx-auto px-4 pt-4"
    flashContainer.innerHTML = `
      <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-md">
        ${message}
      </div>
    `
    
    // Insert after header
    const header = document.querySelector('.bg-white.shadow-sm')
    header.insertAdjacentElement('afterend', flashContainer)
    
    // Remove after 5 seconds
    setTimeout(() => flashContainer.remove(), 5000)
  }

  updateSubmitButton() {
    const branchSelected = this.branchSelectTarget.value !== "" && this.branchSelectTarget.value !== null
    const allReady = this.hasLocation && this.hasSelfie && branchSelected
    
    // Debug logging
    console.log("Form validation status:", {
      branchSelected: branchSelected,
      branchValue: this.branchSelectTarget.value,
      hasLocation: this.hasLocation,
      hasSelfie: this.hasSelfie,
      latValue: this.latInputTarget.value,
      lngValue: this.lngInputTarget.value,
      selfieValue: this.selfieInputTarget.value ? "Present" : "Missing",
      selfieLength: this.selfieInputTarget.value.length
    })
    
    if (allReady) {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.classList.remove("bg-gray-400")
      this.submitButtonTarget.classList.add("bg-blue-600", "hover:bg-blue-700")
      this.submitButtonTarget.textContent = "Complete Clock Entry"
    } else {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.classList.add("bg-gray-400")
      this.submitButtonTarget.classList.remove("bg-blue-600", "hover:bg-blue-700")
      
      if (!branchSelected) {
        this.submitButtonTarget.textContent = "Select branch first"
      } else if (!this.hasLocation) {
        this.submitButtonTarget.textContent = "Getting location..."
      } else if (!this.hasSelfie) {
        this.submitButtonTarget.textContent = "Take selfie first"
      }
    }
  }

  handleSuccess(event) {
    const response = event.detail[0]
    console.log("Clock-in success:", response)
    
    if (response.success) {
      this.showSuccessMessage(response.message)
      // Reset form state
      this.resetForm()
    } else {
      this.showErrorMessage(response.message)
    }
  }

  handleError(event) {
    console.log("Clock-in error:", event.detail)
    const response = event.detail[0]
    
    if (response && response.message) {
      this.showErrorMessage(response.message)
    } else {
      this.showErrorMessage("An error occurred while processing your request")
    }
  }

  showSuccessMessage(message) {
    this.showFlashMessage(message, 'success')
  }

  showErrorMessage(message) {
    this.showFlashMessage(message, 'error')
  }

  showFlashMessage(message, type) {
    // Remove any existing flash messages
    const existingFlash = document.querySelector('.flash-message')
    if (existingFlash) {
      existingFlash.remove()
    }

    // Create new flash message
    const flashContainer = document.createElement('div')
    flashContainer.className = "max-w-md mx-auto px-4 pt-4 flash-message"
    
    const bgColor = type === 'success' ? 'bg-green-50 border-green-200 text-green-700' : 'bg-red-50 border-red-200 text-red-700'
    
    flashContainer.innerHTML = `
      <div class="${bgColor} px-4 py-3 rounded-md">
        ${message}
      </div>
    `
    
    // Insert after header
    const header = document.querySelector('.bg-white.shadow-sm')
    header.insertAdjacentElement('afterend', flashContainer)
    
    // Remove after 5 seconds
    setTimeout(() => flashContainer.remove(), 5000)
  }

  resetForm() {
    // Reset form state for next clock entry
    this.hasSelfie = false
    this.selfieInputTarget.value = ""
    
    // Reset camera display
    this.canvasTarget.classList.add("hidden")
    this.placeholderTarget.classList.remove("hidden")
    
    // Reset buttons
    this.retakeButtonTarget.classList.add("hidden")
    this.startButtonTarget.classList.remove("hidden")
    
    // Unlock branch selector
    this.branchSelectTarget.classList.remove("bg-gray-100", "cursor-not-allowed")
    this.branchSelectTarget.style.pointerEvents = "auto"
    
    this.updateSubmitButton()
  }

}