// MapContainer hook: pan/zoom the map image, track pin positions, and
// coordinate pin placement / selection clicks.
//
// Pin coordinates are normalized to the image content area (accounting for
// object-contain letterboxing), not the container, so pins track the image
// correctly across container resizes (e.g. devtools opens).

const MIN_SCALE = 1
const MAX_SCALE = 10

export default {
  mounted() {
    this.scale = 1
    this.tx = 0
    this.ty = 0
    this.dragging = false
    this.dragStartX = 0
    this.dragStartY = 0

    this.img = () => this.el.querySelector("img")

    // Compute the image content area within the container, accounting for
    // object-contain letterboxing. Pin coordinates are normalized to this
    // content area (not the container) so they track the image correctly
    // when the container's aspect ratio changes (e.g. devtools opens).
    this.imageMetrics = () => {
      const W = this.el.offsetWidth
      const H = this.el.offsetHeight
      const img = this.img()
      let contentW = W, contentH = H, ox = 0, oy = 0
      if (img && img.naturalWidth && img.naturalHeight) {
        const imgAspect = img.naturalWidth / img.naturalHeight
        const boxAspect = W / H
        if (imgAspect > boxAspect) {
          contentW = W
          contentH = W / imgAspect
          oy = (H - contentH) / 2
        } else {
          contentH = H
          contentW = H * imgAspect
          ox = (W - contentW) / 2
        }
      }
      return { W, H, contentW, contentH, ox, oy }
    }

    // Position each pin at its exact pixel coordinate, accounting for
    // pan/zoom and the image content letterbox. Pin coords are relative
    // to the image content area, so they track correctly across resizes.
    this.updatePinPositions = () => {
      const overlay = this.el.querySelector("[data-pins-overlay]")
      if (!overlay) return
      const { contentW, contentH, ox, oy } = this.imageMetrics()
      overlay.querySelectorAll("[data-pin],[data-pending-pin]").forEach(el => {
        const x = parseFloat(el.dataset.pinX || 0)
        const y = parseFloat(el.dataset.pinY || 0)
        el.style.left = `${this.scale * (x * contentW + ox) + this.tx}px`
        el.style.top = `${this.scale * (y * contentH + oy) + this.ty}px`
      })
    }

    this.applyTransform = () => {
      const img = this.img()
      if (!img) return
      img.style.transformOrigin = "0 0"
      img.style.transform = `translate(${this.tx}px, ${this.ty}px) scale(${this.scale})`
      this.updatePinPositions()
    }

    this.reset = () => {
      this.scale = 1
      this.tx = 0
      this.ty = 0
      this.applyTransform()
      this.syncUI()
    }

    this.clamp = () => {
      const W = this.el.offsetWidth
      const H = this.el.offsetHeight
      const img = this.img()
      const s = this.scale

      let ox = 0, oy = 0
      if (img && img.naturalWidth && img.naturalHeight) {
        if (img.naturalWidth / img.naturalHeight > W / H) {
          oy = (H - W * img.naturalHeight / img.naturalWidth) / 2
        } else {
          ox = (W - H * img.naturalWidth / img.naturalHeight) / 2
        }
      }

      const txMax = -ox * s
      const txMin = W * (1 - s) + ox * s
      this.tx = txMin > txMax
        ? (txMin + txMax) / 2
        : Math.min(txMax, Math.max(txMin, this.tx))

      const tyMax = -oy * s
      const tyMin = H * (1 - s) + oy * s
      this.ty = tyMin > tyMax
        ? (tyMin + tyMax) / 2
        : Math.min(tyMax, Math.max(tyMin, this.ty))
    }

    this.applyZoom = (factor, originX, originY) => {
      const newScale = Math.min(MAX_SCALE, Math.max(MIN_SCALE, this.scale * factor))
      if (newScale <= MIN_SCALE) {
        this.scale = MIN_SCALE
        this.tx = 0
        this.ty = 0
      } else {
        const ratio = newScale / this.scale
        this.tx = originX - ratio * (originX - this.tx)
        this.ty = originY - ratio * (originY - this.ty)
        this.scale = newScale
      }
      this.clamp()
      this.applyTransform()
      this.syncUI()
    }

    this.zoomFromCenter = (factor) => {
      if (!this.img()) return
      const rect = this.el.getBoundingClientRect()
      this.applyZoom(factor, rect.width / 2, rect.height / 2)
    }

    this.syncUI = () => {
      const zoomInBtn = document.getElementById("zoom-in-btn")
      const zoomOutBtn = document.getElementById("zoom-out-btn")
      const resetBtn = document.getElementById("reset-view-btn")
      if (zoomInBtn) zoomInBtn.disabled = this.scale >= MAX_SCALE
      if (zoomOutBtn) zoomOutBtn.disabled = this.scale <= MIN_SCALE
      if (resetBtn) resetBtn.disabled = this.scale <= MIN_SCALE
      this.el.style.cursor = this.scale > MIN_SCALE ? "grab" : ""
    }

    this.onWheel = (e) => {
      if (!this.img()) return
      e.preventDefault()
      const rect = this.el.getBoundingClientRect()
      this.applyZoom(e.deltaY < 0 ? 1.1 : 1 / 1.1, e.clientX - rect.left, e.clientY - rect.top)
    }

    this.onMouseDown = (e) => {
      if (e.button !== 0 || this.scale <= MIN_SCALE) return
      if (e.target.closest("button")) return
      this.dragging = true
      this.dragStartX = e.clientX - this.tx
      this.dragStartY = e.clientY - this.ty
      this.el.style.cursor = "grabbing"
      e.preventDefault()
    }

    this.onMouseMove = (e) => {
      if (!this.dragging) return
      this.tx = e.clientX - this.dragStartX
      this.ty = e.clientY - this.dragStartY
      this.clamp()
      this.applyTransform()
    }

    this.onMouseUp = () => {
      if (!this.dragging) return
      this.dragging = false
      this.el.style.cursor = this.scale > 1 ? "grab" : ""
    }

    this.el.addEventListener("wheel", this.onWheel, { passive: false })
    this.el.addEventListener("mousedown", this.onMouseDown)
    window.addEventListener("mousemove", this.onMouseMove)
    window.addEventListener("mouseup", this.onMouseUp)
    this.el.addEventListener("map:zoom-in", () => this.zoomFromCenter(1.5))
    this.el.addEventListener("map:zoom-out", () => this.zoomFromCenter(1 / 1.5))
    this.el.addEventListener("map:reset-view", () => this.reset())

    // Map click handler: pin placement or background deselect
    this.onPinClick = (e) => {
      const onPin = !!e.target.closest("[data-pin]")
      const onButton = !!e.target.closest("button")
      const onSidebar = !!e.target.closest("[data-sidebar]")

      if (this.el.classList.contains("cursor-crosshair")) {
        // Pin placement mode — place pin on background click
        if (onButton || onPin || onSidebar) return
        e.stopPropagation()

        const rect = this.el.getBoundingClientRect()
        const rawX = e.clientX - rect.left
        const rawY = e.clientY - rect.top
        const { contentW, contentH, ox, oy } = this.imageMetrics()
        // Invert the display formula in updatePinPositions:
        //   px = scale * (x * contentW + ox) + tx
        //   x  = ((px - tx) / scale - ox) / contentW
        const x = Math.max(0, Math.min(1, (((rawX - this.tx) / this.scale) - ox) / contentW))
        const y = Math.max(0, Math.min(1, (((rawY - this.ty) / this.scale) - oy) / contentH))
        if (this.el.dataset.moveMode === "true") {
          this.pushEvent("move_pin_to", { x, y })
        } else {
          this.pushEvent("pin_clicked", { x, y })
        }
      }
    }
    this.el.addEventListener("click", this.onPinClick)

    this._lastMapId = this.el.dataset.mapId
    this.syncUI()

    // Re-clamp, re-apply, and reposition pins whenever the container
    // resizes (devtools open/close, window resize, etc.)
    this.resizeObserver = new ResizeObserver(() => {
      this.clamp()
      this.applyTransform()
      this.syncUI()
    })
    this.resizeObserver.observe(this.el)
  },

  updated() {
    const mapId = this.el.dataset.mapId
    if (mapId !== this._lastMapId) {
      this._lastMapId = mapId
      this.reset()
    } else {
      // Re-apply transform so newly rendered pins get correct position
      this.applyTransform()
    }
  },

  destroyed() {
    this.el.removeEventListener("wheel", this.onWheel)
    this.el.removeEventListener("mousedown", this.onMouseDown)
    window.removeEventListener("mousemove", this.onMouseMove)
    window.removeEventListener("mouseup", this.onMouseUp)
    this.el.removeEventListener("click", this.onPinClick)
    if (this.resizeObserver) this.resizeObserver.disconnect()
  }
}
