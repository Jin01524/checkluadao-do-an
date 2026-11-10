package com.checkluadao.app_checkluadao_ttnt

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import kotlin.math.roundToInt

class ConversationScanTest {

    @Test
    fun testRiskScoreParsing() {
        val jsonString = """
            {
                "isScam": true,
                "confidenceScore": 88,
                "assessment": {
                    "status": "high_risk",
                    "riskScore": 88,
                    "reason": "Yêu cầu chuyển tiền"
                },
                "level": "Nguy cơ cao",
                "suggestedReply": {
                    "text": "Bạn là ai?"
                }
            }
        """.trimIndent()

        val data = JSONObject(jsonString)
        val assessment = data.optJSONObject("assessment")

        // Validate score resolution precedence
        val rawScore = if (assessment != null && assessment.has("riskScore")) {
            assessment.opt("riskScore")
        } else {
            data.opt("confidenceScore")
        }
        val number = when (rawScore) {
            is Number -> rawScore.toDouble()
            is String -> rawScore.toDoubleOrNull()
            else -> null
        }
        assertNotNull(number)
        assertEquals(88, number!!.roundToInt())

        // Validate suggested reply parsing from object or string
        val replyFromObj = data.optJSONObject("suggestedReply")?.optString("text")?.takeIf { it.isNotBlank() }
            ?: assessment?.optString("suggestedReply")?.takeIf { it.isNotBlank() }
            ?: data.optString("suggestedReply").takeIf { it.isNotBlank() }
        assertEquals("Bạn là ai?", replyFromObj)
    }

    @Test
    fun testStringSuggestedReplyParsing() {
        val jsonString = """
            {
                "isScam": false,
                "confidenceScore": 15,
                "suggestedReply": "Xin vui lòng gọi lại sau."
            }
        """.trimIndent()

        val data = JSONObject(jsonString)
        val assessment = data.optJSONObject("assessment")
        val reply = data.optJSONObject("suggestedReply")?.optString("text")?.takeIf { it.isNotBlank() }
            ?: assessment?.optString("suggestedReply")?.takeIf { it.isNotBlank() }
            ?: data.optString("suggestedReply").takeIf { it.isNotBlank() }
        assertEquals("Xin vui lòng gọi lại sau.", reply)
    }
}
