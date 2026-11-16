function test_mask_and_json()
check(strcmp(vault.maskAccount('10010020001'), '****0001'), 'mask keeps last 4');
check(strcmp(vault.maskAccount('1234'), '****'), 'short numbers are fully masked');
scrubbed = vault.scrubSecrets('Bearer abc.def and account 3353431574710163189587446');
check(isempty(strfind(scrubbed, '3353431574710163189587446')), 'long ids are scrubbed'); %#ok<STREMP>
check(~isempty(strfind(scrubbed, 'Bearer ****')), 'bearer tokens are scrubbed'); %#ok<STREMP>
raw = '{"accountId": 1000000000000000000000001, "amount": 12.5}';
data = vault.decodeApiJson(raw);
check(strcmp(char(data.accountId), '1000000000000000000000001'), '25-digit account id survives');
check(abs(data.amount - 12.5) < 1e-9, 'ordinary amounts stay numeric');
check(strcmp(vault.base64Encode('hello'), 'aGVsbG8='), 'base64 hello');
check(strcmp(vault.formatRand(1240), 'R1 240.00'), 'rand format');
check(strcmp(vault.merchantStem('VODACOM 0401'), 'vodacom'), 'vodacom stem');
check(strcmp(vault.merchantStem('AON SA 293 2302Q58'), 'aon sa'), 'aon stem');
check(strcmp(vault.merchantStem('AFRIHOST A123456 EBC9C'), 'afrihost ebc'), 'afrihost stem');
check(strcmp(vault.merchantStem('STANCOM 352Kjoe.smith'), 'stancom kjoe smith'), 'salary stem');
check(strcmp(vault.merchantStem('STANCOM 352KSSS WEEKLY PAYM'), 'stancom ksss weekly'), 'weekly stem stays distinct');
check(abs(vault.percentile([1 2 3 4], 50) - 2.5) < 1e-9, 'percentile midpoint');
rules = vault.loadMerchantRules(fullfile(vault.repoRoot(), 'shared', 'merchant-rules.json'));
check(strcmp(vault.classifyTransaction('VODACOM 0401', 'DebitOrders', rules), 'subscriptions'), 'vodacom category');
check(strcmp(vault.classifyTransaction('SUPERSPAR KURUMAN', 'CardPurchases', rules), 'groceries'), 'spar category');
check(strcmp(vault.classifyTransaction('STANCOM 352Kjoe.smith', 'Deposits', rules), 'income'), 'salary category');
check(strcmp(vault.classifyTransaction('MYSTERY SHOP', 'CardPurchases', rules), 'card'), 'unmatched card type');
check(strcmp(vault.classifyTransaction('MYSTERY SHOP', 'DebitOrders', rules), 'debit_order'), 'unmatched debit order');
end
