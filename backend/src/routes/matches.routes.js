const express = require("express");
const { requireAuth } = require("../middleware/auth");
const {
  nearby,
  requestConsent,
  respondConsent,
  submitDetail,
  getConsent,
} = require("../controllers/matches.controller");

const router = express.Router();

router.get("/nearby", requireAuth, nearby);
router.post("/:otherUserId/consent/request", requireAuth, requestConsent);
router.post("/consent/:roomId/respond", requireAuth, respondConsent);
router.post("/consent/:roomId/detail", requireAuth, submitDetail);
router.get("/consent/:roomId", requireAuth, getConsent);

module.exports = router;
