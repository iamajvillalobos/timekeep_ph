import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ 
    "video", "canvas", "placeholder", "startButton", "captureButton", "retakeButton", 
    "latInput", "lngInput", "selfieInput", "form", "smartButton", "cameraModal",
    "confirmButton", "branchInput", "entryTypeInput", "liveTimer", "todaysHours",
    "clockOutButton"
  ]
  
  static values = {
    employeeState: String,
    action: String,
    requiresSelfie: Boolean
  }

  connect() {
    console.log("Smart Clock-in controller connected")
    console.log("Employee state:", this.employeeStateValue)
    console.log("Action:", this.actionValue)
    console.log("Requires selfie:", this.requiresSelfieValue)
    
    this.stream = null
    this.hasLocation = false
    this.hasSelfie = false
    
    // Get GPS location on connect
    this.getLocation()
    
    // Add form submission handler
    this.formTarget.addEventListener('ajax:success', this.handleSuccess.bind(this))
    this.formTarget.addEventListener('ajax:error', this.handleError.bind(this))
    
    // Start live timer if clocked in
    this.startLiveTimer()
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
    
    // Show confirm button
    if (this.hasConfirmButtonTarget) {
      this.confirmButtonTarget.classList.remove("hidden")
    }
    
    // Stop camera stream
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop())
      this.stream = null
    }
    
    this.hasSelfie = true
    this.updateSubmitButton()
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
    
    // Hide confirm button if it exists
    if (this.hasConfirmButtonTarget) {
      this.confirmButtonTarget.classList.add("hidden")
    }
    
    this.updateSubmitButton()
  }

  getLocation() {
    console.log("Getting location...")
    
    if (!navigator.geolocation) {
      this.showLocationError("Geolocation not supported")
      return
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.latInputTarget.value = position.coords.latitude
        this.lngInputTarget.value = position.coords.longitude
        this.hasLocation = true
        
        console.log(`Location acquired: ${position.coords.latitude.toFixed(4)}, ${position.coords.longitude.toFixed(4)}`)
        
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
    console.error("Location error:", message)
    this.showErrorMessage(message)
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
    // In the smart dashboard, branch is pre-selected and we don't need the old submit button validation
    // This method is now mainly for legacy compatibility
    console.log("Form validation status:", {
      hasLocation: this.hasLocation,
      hasSelfie: this.hasSelfie,
      latValue: this.latInputTarget.value,
      lngValue: this.lngInputTarget.value,
      selfieValue: this.selfieInputTarget.value ? "Present" : "Missing",
      selfieLength: this.selfieInputTarget.value.length
    })
  }

  handleSuccess(event) {
    const response = event.detail[0]
    console.log("Clock-in success:", response)
    
    // Hide loading state
    this.hideVerificationLoading()
    
    if (response.success) {
      // Show enhanced success message with verification details
      let message = response.message
      if (response.verification_status === 'verified' && response.confidence) {
        message += ` (Face verified: ${Math.round(response.confidence)}% confidence)`
      } else if (response.verification_status === 'bypassed') {
        message += ` (No face verification required)`
      }
      
      this.showSuccessMessage(message)
      
      // Wait 2 seconds then refresh to show updated state
      setTimeout(() => {
        window.location.reload()
      }, 2000)
    } else {
      this.showErrorMessage(response.message)
    }
  }

  handleError(event) {
    console.log("Clock-in error:", event.detail)
    const response = event.detail[0]
    
    // Hide loading state
    this.hideVerificationLoading()
    
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
    
    this.updateSubmitButton()
  }

  // Smart Clock-In Methods
  smartClockAction() {
    console.log("Smart clock action triggered:", this.actionValue)
    console.log("Requires selfie:", this.requiresSelfieValue)
    
    if (!this.hasLocation) {
      this.showErrorMessage("Getting your location... Please wait.")
      return
    }

    // Set entry type based on employee state
    this.entryTypeInputTarget.value = this.actionValue
    
    // Branch is already pre-selected in the form
    if (!this.branchInputTarget.value) {
      this.showErrorMessage("No branch available. Please contact your administrator.")
      return
    }

    // Check if selfie is required for this action
    if (this.requiresSelfieValue) {
      // Show camera modal for selfie
      this.showCameraModal()
    } else {
      // No selfie required, submit directly
      this.submitDirectly()
    }
  }

  // Clock Out Action (secondary button when clocked in)
  clockOutAction() {
    console.log("Clock out action triggered")
    
    if (!this.hasLocation) {
      this.showErrorMessage("Getting your location... Please wait.")
      return
    }

    // Set entry type to clock_out
    this.entryTypeInputTarget.value = "clock_out"
    
    // Branch is already pre-selected in the form
    if (!this.branchInputTarget.value) {
      this.showErrorMessage("No branch available. Please contact your administrator.")
      return
    }

    // Clock out never requires selfie, submit directly
    this.submitDirectly()
  }

  submitDirectly() {
    // Clear any existing selfie data since it's not required
    this.selfieInputTarget.value = ""
    
    // Submit the form directly
    console.log("Submitting without selfie...")
    if (this.formTarget.requestSubmit) {
      this.formTarget.requestSubmit()
    } else {
      this.formTarget.submit()
    }
  }

  showCameraModal() {
    this.cameraModalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  closeCameraModal() {
    this.cameraModalTarget.classList.add("hidden")
    document.body.style.overflow = "auto"
    
    // Reset camera state
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop())
      this.stream = null
    }
    
    this.hasSelfie = false
    this.canvasTarget.classList.add("hidden")
    this.placeholderTarget.classList.remove("hidden")
    this.retakeButtonTarget.classList.add("hidden")
    this.confirmButtonTarget.classList.add("hidden")
    this.startButtonTarget.classList.remove("hidden")
  }

  confirmSelfie() {
    if (!this.hasSelfie) {
      this.showErrorMessage("Please take a selfie first.")
      return
    }

    // Close modal
    this.closeCameraModal()
    
    // Show verification loading state
    this.showVerificationLoading()
    
    // Log form data before submission
    console.log("Form data:", {
      branch_id: this.branchInputTarget.value,
      entry_type: this.entryTypeInputTarget.value,
      gps_latitude: this.latInputTarget.value,
      gps_longitude: this.lngInputTarget.value,
      selfie_data: this.selfieInputTarget.value ? "Present" : "Empty"
    })

    // Submit the form using requestSubmit for better Rails UJS compatibility
    console.log("Submitting form with selfie...")
    if (this.formTarget.requestSubmit) {
      this.formTarget.requestSubmit()
    } else {
      // Fallback for older browsers
      this.formTarget.submit()
    }
  }


  showVerificationLoading() {
    // Remove any existing messages
    const existingFlash = document.querySelector('.flash-message')
    if (existingFlash) {
      existingFlash.remove()
    }

    // Create verification loading message
    const loadingContainer = document.createElement('div')
    loadingContainer.className = "max-w-md mx-auto px-4 pt-4 flash-message verification-loading"
    
    loadingContainer.innerHTML = `
      <div class="bg-blue-50 border border-blue-200 text-blue-700 px-4 py-3 rounded-md">
        <div class="flex items-center">
          <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-600 mr-3"></div>
          <span>Verifying your face... Please wait.</span>
        </div>
      </div>
    `
    
    // Insert after header
    const header = document.querySelector('.bg-white.shadow-lg')
    header.insertAdjacentElement('afterend', loadingContainer)
  }

  hideVerificationLoading() {
    const loadingElement = document.querySelector('.verification-loading')
    if (loadingElement) {
      loadingElement.remove()
    }
  }

  startLiveTimer() {
    if (!this.hasLiveTimerTarget) return
    
    const startTime = parseInt(this.liveTimerTarget.dataset.startTime)
    if (!startTime) return

    this.timerInterval = setInterval(() => {
      const currentTime = Math.floor(Date.now() / 1000)
      const elapsed = currentTime - startTime
      const hours = Math.floor(elapsed / 3600)
      const minutes = Math.floor((elapsed % 3600) / 60)
      
      const timeText = hours > 0 
        ? `Working for ${hours}h ${minutes}m`
        : `Working for ${minutes}m`
      
      this.liveTimerTarget.textContent = timeText
      
      // Update today's hours in real-time
      if (this.hasTodaysHoursTarget) {
        const currentHours = (elapsed / 3600).toFixed(2)
        this.todaysHoursTarget.innerHTML = `${currentHours} <span class="text-sm font-normal text-gray-500">hrs</span>`
      }
    }, 60000) // Update every minute
  }


}