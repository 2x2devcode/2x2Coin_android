package com.coin2x2.wallet;

import android.app.Activity;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.biometric.BiometricManager;
import androidx.biometric.BiometricPrompt;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentActivity;

/**
 * Android biometric unlock helper for the Qt wallet activity.
 */
public final class BiometricHelper {

    private BiometricHelper() {}

    public static void authenticate(@NonNull Activity activity) {
        if (!(activity instanceof FragmentActivity)) {
            return;
        }

        FragmentActivity fragmentActivity = (FragmentActivity) activity;
        BiometricManager manager = BiometricManager.from(activity);
        int canAuth = manager.canAuthenticate(
                BiometricManager.Authenticators.BIOMETRIC_STRONG
                        | BiometricManager.Authenticators.BIOMETRIC_WEAK);

        if (canAuth != BiometricManager.BIOMETRIC_SUCCESS) {
            return;
        }

        BiometricPrompt.PromptInfo promptInfo = new BiometricPrompt.PromptInfo.Builder()
                .setTitle("2X2Coin Wallet")
                .setSubtitle("Desbloquear carteira")
                .setNegativeButtonText("Cancelar")
                .build();

        BiometricPrompt prompt = new BiometricPrompt(
                fragmentActivity,
                ContextCompat.getMainExecutor(activity),
                new BiometricPrompt.AuthenticationCallback() {
                    @Override
                    public void onAuthenticationSucceeded(
                            @NonNull BiometricPrompt.AuthenticationResult result) {
                        super.onAuthenticationSucceeded(result);
                    }
                });

        prompt.authenticate(promptInfo);
    }
}
