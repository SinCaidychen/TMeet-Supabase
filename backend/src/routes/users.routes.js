const express = require("express");
const { requireAuth } = require("../middleware/auth");
const { me, updateLocation, updateOnboarding } = require("../controllers/users.controller");

const router = express.Router();

router.get("/me", requireAuth, me);
router.patch("/me/location", requireAuth, updateLocation);
router.patch("/me/onboarding", requireAuth, updateOnboarding);

module.exports = router;
