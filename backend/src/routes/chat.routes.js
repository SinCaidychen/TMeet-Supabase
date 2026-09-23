const express = require("express");
const { requireAuth } = require("../middleware/auth");
const { listRooms, createGroupRoom, listMessages } = require("../controllers/chat.controller");

const router = express.Router();

router.get("/rooms", requireAuth, listRooms);
router.post("/rooms/group", requireAuth, createGroupRoom);
router.get("/rooms/:roomId/messages", requireAuth, listMessages);

module.exports = router;
